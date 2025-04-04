self.addEventListener('notificationclick', (event) => {
    event.notification.close();
    const payload = event.notification.data?.payload;
    
    event.waitUntil(
      clients.matchAll({
        type: 'window',
        includeUncontrolled: true  // Important for PWA detection
      }).then((clientList) => {
        // Check if there's already a window open
        const existingClient = clientList.find(client => {
          // Match your PWA's URL pattern
          return client.url.startsWith('https://vigilantus.us') || 
                 client.url.startsWith('https://localhost:') ||
                 client.url.startsWith('http://localhost:');
        });
  
        if (existingClient) {
          // Focus the existing window
          existingClient.focus();
          // Send the payload to the existing window
          existingClient.postMessage({
            type: 'notificationClick',
            payload:  JSON.stringify(payload)
          });
        } else {
          // Open new window only if no existing one found
          return clients.openWindow('/?notification_payload=' + 
            encodeURIComponent(payload || ''));
        }
      })
    );
  });