import { ChildProcess } from 'child_process';

declare global {
  var __TEST_SERVER__: ChildProcess | undefined;
}
