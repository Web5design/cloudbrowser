var PhoneBook = require("./phonebook"),
    CloudBrowser = require('../../../');

CloudBrowser.createServer({
    knockout: true,
    defaultApp: CloudBrowser.createApplication({
        entryPoint  : 'table.html',
        mountPoint  : '/',
        sharedState  : new PhoneBook()
    })
});
