import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:openai_dart/openai_dart.dart';

Future<String?> uploadFileToOpenAI(
  String apiKey,
  String filePath,
  String purpose,
) async {
  final file = File(filePath);
  if (!file.existsSync()) return null;

  final uri = Uri.parse('https://api.openai.com/v1/files');
  final request =
      http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $apiKey'
        ..files.add(await http.MultipartFile.fromPath('file', filePath))
        ..fields['purpose'] = purpose;

  final response = await request.send();
  if (response.statusCode == 200) {
    final body = await response.stream.bytesToString();
    final json = jsonDecode(body);
    return json['id'];
  }
  return null;
}

void main() async {
  final openaiApiKey = Platform.environment['OPENAI_API_KEY'];
  final client = OpenAIClient(apiKey: openaiApiKey);

  final filePath = 'path/to/your/file.txt';
  final fileId = await uploadFileToOpenAI(
    openaiApiKey!,
    filePath,
    'assistants',
  );
  if (fileId == null) return;

  final vectorStore = await client.createVectorStore(
    request: CreateVectorStoreRequest(),
  );
  final vectorStoreId = vectorStore.id;

  await client.createVectorStoreFile(
    vectorStoreId: vectorStoreId,
    request: CreateVectorStoreFileRequest(fileId: fileId),
  );

  final assistant = await client.createAssistant(
    request: CreateAssistantRequest(
      model: AssistantModel.modelId('gpt-4o-latest'),
      tools: [AssistantTools.fileSearch(type: 'file_search')],
      toolResources: ToolResources(
        fileSearch: ToolResourcesFileSearch(vectorStoreIds: [vectorStoreId]),
      ),
    ),
  );
  final assistantId = assistant.id;

  final thread = await client.createThread(request: CreateThreadRequest());
  final threadId = thread.id;

  await client.createThreadMessage(
    threadId: threadId,
    request: CreateMessageRequest(
      role: MessageRole.user,
      content: CreateMessageRequestContent.text('Summarize the uploaded file.'),
    ),
  );

  final run = await client.createThreadRun(
    threadId: threadId,
    request: CreateRunRequest(assistantId: assistantId),
  );

  RunObject runStatus = run;
  while (runStatus.status == RunStatus.queued ||
      runStatus.status == RunStatus.inProgress) {
    await Future.delayed(Duration(seconds: 2));
    runStatus = await client.getThreadRun(threadId: threadId, runId: run.id);
  }

  if (runStatus.status == RunStatus.completed) {
    final messages = await client.listThreadMessages(threadId: threadId);
    final aiContent = messages.data.first.content
        .whereType<MessageContentText>()
        .map((content) => content.value)
        .join('\n');
    print('AI response: $aiContent');
  }
}
