var @_port = chrome.runtime.connect {name: "onClicked"};
@_port.sendMessage{
  message: "YES"
};