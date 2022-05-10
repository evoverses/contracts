const { upgradeProxy } = require('./functions');

upgradeProxy("vEVOVestingUpgradeable", "0xE8588d85DB8DBCE0Fad08e8943E6Cc0Bf3F5bb7d")
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })