const { contextBridge } = require('electron');

contextBridge.exposeInMainWorld('api', {
  // placeholder for future IPC methods
});