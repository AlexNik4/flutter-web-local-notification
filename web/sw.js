self.addEventListener('notificationclick', (event) => {
    event.notification.close();
    const payload = event.notification.data?.payload;
    
    // Get the current origin from the registration scope
    const currentOrigin = new URL(self.registration.scope).origin;
    
    event.waitUntil(
      clients.matchAll({
        type: 'window',
        includeUncontrolled: true
      }).then((clientList) => {
        // Find existing client matching our origin
        const existingClient = clientList.find(client => {
          try {
            const clientUrl = new URL(client.url);
            return clientUrl.origin === currentOrigin;
          } catch (e) {
            return false;
          }
        });
  
        if (existingClient) {
          // Focus the existing window
          existingClient.focus();
          // Send the payload to the existing window
          existingClient.postMessage({
            type: 'notificationClick',
            payload: JSON.stringify(payload)
          });
        } else {
          // Open new window only if no existing one found
          return clients.openWindow(currentOrigin + '/?notification_payload=' + 
            encodeURIComponent(payload || ''));
        }
      })
    );
  });