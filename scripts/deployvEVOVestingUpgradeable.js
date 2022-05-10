const { deployProxy } = require('./functions');
// 0xE8588d85DB8DBCE0Fad08e8943E6Cc0Bf3F5bb7d
deployProxy("vEVOVestingUpgradeable")
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })