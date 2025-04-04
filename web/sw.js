self.addEventListener('notificationclick', (event) => {
    event.notification.close();
    
    // Extract the payload from the notification data
    const payload = event.notification.data?.payload;
    
    // Focus the app if it's already open
    event.waitUntil(
      clients.matchAll({type: 'window'}).then((clientList) => {
        if (clientList.length > 0) {
          let client = clientList[0];
          for (let i = 0; i < clientList.length; i++) {
            if (clientList[i].focused) {
              client = clientList[i];
            }
          }
          return client.focus();
        }
        return clients.openWindow('/?notification_payload=' + encodeURIComponent(payload));
      })
    );
  });