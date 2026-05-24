import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    name: Translation.tr("LocalSend")
    statusText: {
        if (LocalSend.currentTransfer !== null) {
            const files = LocalSend.currentTransfer.files;
            if (files && files.length > 0) {
                const name = files[0].name;
                const count = files.length;
                if (count > 1) {
                    return Translation.tr("Incoming: %1 (+%2)").arg(name).arg(count - 1);
                } else {
                    return Translation.tr("Incoming: %1").arg(name);
                }
            }
            return Translation.tr("Incoming transfer");
        }
        if (LocalSend.sending) {
            const files = LocalSend.droppedFiles;
            if (files && files.length > 0) {
                const name = files[0].name;
                const count = files.length;
                if (count > 1) {
                    return Translation.tr("Sending: %1 (+%2)").arg(name).arg(count - 1);
                } else {
                    return Translation.tr("Sending: %1").arg(name);
                }
            }
            return Translation.tr("Sending...");
        }
        if (LocalSend.droppedFiles.length > 0) {
            const files = LocalSend.droppedFiles;
            const name = files[0].name;
            const count = files.length;
            if (count > 1) {
                return Translation.tr("Pending: %1 (+%2)").arg(name).arg(count - 1);
            } else {
                return Translation.tr("Pending: %1").arg(name);
            }
        }
        return LocalSend.serverRunning ? Translation.tr("Active") : Translation.tr("Offline");
    }

    toggled: LocalSend.serverRunning
    icon: "share"
    hasMenu: true
    
    mainAction: () => {
        if (LocalSend.serverRunning) {
            LocalSend.stopServer();
        } else {
            LocalSend.startServer();
        }
    }

    tooltipText: Translation.tr("LocalSend File Share")
}
