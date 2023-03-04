# truffle-flatten

Thanks to [Nomic Labs](https://github.com/nomiclabs/truffle-flattener) for the heavy lifting.

This truffle plugin does very little in addition to what the base tool Nomic Labs has provided.

- It extracts all pragmas to the top of the flattened file
- the highest pragma version is selected
- saves the flattened source into `flatten/Flattened.sol` 


## Installation
1. Install the plugin with npm
    ```
    npm install truffle-flatten
    ```
1. Add the plugin to your `truffle.js` or `truffle-config.js` file
    ```js
    module.exports = {
      /* ... rest of truffle-config */

      plugins: [
        'truffle-flatten'
      ]
    }
   ```

## Usage
```
truffle run flatten <Source.sol>
```

