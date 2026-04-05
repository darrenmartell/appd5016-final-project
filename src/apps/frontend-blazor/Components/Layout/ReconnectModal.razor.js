// Set up event handlers when the reconnect modal exists.
const reconnectModal = document.getElementById("components-reconnect-modal");
const retryButton = document.getElementById("components-reconnect-button");
const resumeButton = document.getElementById("components-resume-button");

if (reconnectModal) {
    reconnectModal.addEventListener("components-reconnect-state-changed", handleReconnectStateChanged);
}

if (retryButton) {
    retryButton.addEventListener("click", retry);
}

if (resumeButton) {
    resumeButton.addEventListener("click", resume);
}

function handleReconnectStateChanged(event) {
    if (!reconnectModal) {
        return;
    }

    switch (event.detail.state) {
        case "show":
            reconnectModal.showModal();
            break;
        case "hide":
            reconnectModal.close();
            break;
        case "failed":
            document.addEventListener("visibilitychange", retryWhenDocumentBecomesVisible);
            break;
        case "rejected":
            location.reload();
            break;
        default:
            break;
    }
}

async function retry() {
    if (!reconnectModal) {
        return;
    }

    document.removeEventListener("visibilitychange", retryWhenDocumentBecomesVisible);

    try {
        // Reconnect will asynchronously return:
        // - true to mean success
        // - false to mean we reached the server, but it rejected the connection (e.g., unknown circuit ID)
        // - exception to mean we didn't reach the server (this can be sync or async)
        const successful = await Blazor.reconnect();
        if (!successful) {
            // We have been able to reach the server, but the circuit is no longer available.
            // We'll reload the page so the user can continue using the app as quickly as possible.
            const resumeSuccessful = await Blazor.resumeCircuit();
            if (!resumeSuccessful) {
                location.reload();
            } else {
                reconnectModal.close();
            }
        }
    } catch (err) {
        // We got an exception, server is currently unavailable
        document.addEventListener("visibilitychange", retryWhenDocumentBecomesVisible);
    }
}

async function resume() {
    if (!reconnectModal) {
        return;
    }

    try {
        const successful = await Blazor.resumeCircuit();
        if (!successful) {
            location.reload();
        }
    } catch {
        reconnectModal.classList.replace("components-reconnect-paused", "components-reconnect-resume-failed");
    }
}

async function retryWhenDocumentBecomesVisible() {
    if (document.visibilityState === "visible") {
        await retry();
    }
}
