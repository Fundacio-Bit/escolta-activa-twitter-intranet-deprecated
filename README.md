# Twitter Intranet #
It contains code of the Escolta Activa project's intranet.

## Architecture

* Version: 2.0
* Development Status: Production/Stable 
* Runtime Environment: NodeJS
* Database Environment: Mongo
* Programming Language: CoffeeScript
* User Interface: Web-based
 
## Requirements

###  - NodeJS 

Current version: v8.11.3 (also working with v10.19.0)

Install global packages:

```console
npm install -g webpack@3.3.0
npm install -g gulp@3.9.1
npm install -g coffee-script@1.12.7
```

To get list of globally installed packages: 

```console
npm list -g --depth 0
```

### - MongoDB

Current version: v4.0.9

Create database 'escolta_activa_db', see script in [create-database](create-database.js)


### - Clone the repository

TODO: write github url
```console
git clone https://omoya_fbit@bitbucket.org/ellado_fbit/twitter_intranet.git
```


### - Create output directory

### - Environment variable <b> ESCOLTA_ACTIVA </b>

### - This application depends on another repository, Twitter Reporting, to generate zip files.

## Usage

- Install the dependencies in the local node_modules folder:

    ```console
    npm install
    ```

- Execute gulp to transpile coffee, compile handlebars and place packages in their target folders.

    ```console
    gulp
    ```

- Execute Webpack config to produce the react sections:

    ```console
    webpack --progress -p
    ```

- Run the intranet.

    ```console
    coffee server.coffee
    ```

The website will be available at http://localhost:5000/.

## License

MIT License

Copyright (c) 2020 Fundació BIT

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.