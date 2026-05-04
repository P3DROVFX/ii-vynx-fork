pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    property ListModel commandsModel: ListModel {}
    property bool importing: false

    readonly property string filePath: Directories.commandsPath

    function save() {
        const arr = [];
        for (let i = 0; i < commandsModel.count; i++) {
            const item = commandsModel.get(i);
            const tags = [];
            for (let t = 0; t < item.tags.count; t++) {
                tags.push(item.tags.get(t).modelData);
            }
            arr.push({
                id: item.id,
                command: item.command,
                description: item.description,
                tags
            });
        }
        fileView.setText(JSON.stringify(arr, null, 2));
    }

    function addCommand(command, description, tags) {
        const id = Date.now().toString(36) + Math.random().toString(36).substr(2, 5);
        const tagList = tags.map(t => ({ modelData: t }));
        commandsModel.append({ id, command, description, tags: tagList });
        save();
    }

    function updateCommand(id, command, description, tags) {
        for (let i = 0; i < commandsModel.count; i++) {
            if (commandsModel.get(i).id === id) {
                const tagList = tags.map(t => ({ modelData: t }));
                commandsModel.set(i, { id, command, description, tags: tagList });
                save();
                return;
            }
        }
    }

    function deleteCommand(id) {
        for (let i = 0; i < commandsModel.count; i++) {
            if (commandsModel.get(i).id === id) {
                commandsModel.remove(i);
                save();
                return;
            }
        }
    }

    // Returns array of unique tag strings across all commands
    function allTags() {
        const set = new Set();
        for (let i = 0; i < commandsModel.count; i++) {
            const item = commandsModel.get(i);
            for (let t = 0; t < item.tags.count; t++) {
                const tag = item.tags.get(t).modelData;
                if (tag) set.add(tag);
            }
        }
        return Array.from(set).sort();
    }

    signal importFinished(bool success, string errorMsg)

    function importCommands(path) {
        const plainPath = FileUtils.trimFileProtocol(path);
        importFileView.path = Qt.resolvedUrl("file://" + plainPath);
        importFileView.reload();
    }

    FileView {
        id: importFileView
        path: ""
        onLoaded: {
            const text = importFileView.text();
            if (!text) {
                importFinished(false, "File is empty.");
                return;
            }
            try {
                const data = JSON.parse(text);
                if (!Array.isArray(data)) {
                    importFinished(false, "Invalid format: Expected an array of commands.");
                    return;
                }
                root.importing = true;
                data.forEach(item => {
                    const id = Date.now().toString(36) + Math.random().toString(36).substr(2, 5);
                    const tagList = (item.tags || []).map(t => ({ modelData: t }));
                    commandsModel.append({
                        id: id,
                        command: item.command || "",
                        description: item.description || "",
                        tags: tagList
                    });
                });
                root.importing = false;
                save();
                importFinished(true, "");
            } catch (e) {
                root.importing = false;
                importFinished(false, "Failed to parse JSON: " + e.message);
            }
        }
        onLoadFailed: (error) => {
            importFinished(false, "Could not read file (error " + error + ").");
        }
    }

    FileView {
        id: fileView
        path: Qt.resolvedUrl(root.filePath)
        onLoaded: {
            try {
                const data = JSON.parse(fileView.text());
                commandsModel.clear();
                data.forEach(item => {
                    const tagList = (item.tags || []).map(t => ({ modelData: t }));
                    commandsModel.append({
                        id: item.id || Date.now().toString(36),
                        command: item.command || "",
                        description: item.description || "",
                        tags: tagList
                    });
                });
            } catch (e) {
                console.log("[CommandsService] Error loading: " + e);
            }
        }
        onLoadFailed: (error) => {
            if (error == FileViewError.FileNotFound) {
                console.log("[CommandsService] File not found, creating new file.");
                fileView.setText("[]");
            } else {
                console.log("[CommandsService] Load error: " + error);
            }
        }
    }

    Component.onCompleted: fileView.reload()
}
