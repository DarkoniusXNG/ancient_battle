const fs = require('fs');
const path = require('path');
const chalk = require('chalk');
const readline = require('readline');

const tab = '  ';
const padLenght = 59;

function stringRepeat (string, num) {
  let result = '';
  for (let i = 0; i < num; i++) {
    result += string;
  }
  return result;
}

const walk = function (directoryName, action) {
  fs.readdir(directoryName, function (err, files) {
    if (err) {
      console.error(chalk.red(err));
      return;
    }
    files.forEach(function (file) {
      const fullPath = path.join(directoryName, file);
      fs.stat(fullPath, function (err, f) {
        if (err) {
          console.error(chalk.red(err));
          return;
        }
        if (f.isDirectory()) {
          walk(fullPath, action);
        } else {
          action(fullPath);
        }
      });
    });
  });
};

function cleanKVFile (file) {
  if (file.indexOf('.md') > -1) {
    return;
  }

  // console.log('Cleaning ' + chalk.green(file));

  const lineReader = readline.createInterface({
    input: fs.createReadStream(file)
  });

  let indent = 0;
  let result = '';
  let before = '';
  let error = false;
  let lineNumber = 0;
  lineReader.on('line', (line) => {
    before += line + '\n';
    lineNumber++;
    // replace tabs
    line = line.replace(/\t/g, tab);

    // fix indent
    if (line.indexOf('}') > -1) {
      // decrease indent on }
      indent--;
    }
    line = line.replace(/^ +/g, stringRepeat(tab, indent)); // set indent
    if (line.indexOf('{') > -1) {
      // increase indent on {
      indent++;
    }

    if (!(line.trimStart().startsWith('//'))) {
      // fix padding
      line = line.replace(/" +"/g, '"  "'); // remove spaces between "'s

      const indices = [];
      for (let i = 0; i < line.length; i++) {
        if (line[i] === '"') indices.push(i);
      }

      if (Object.keys(indices).length % 2 === 1) {
        console.error(chalk.red('ERR File "' + file + '" has an uneven number of " at line ' + lineNumber + '.'));
        error = true;
        return;
      }

      if (Object.keys(indices).length > 2 && indices[2] < padLenght) {
        line = line.slice(0, indices[1] + 1) + stringRepeat(' ', padLenght - indices[1] - 2) + line.slice(indices[2]);
      }
    }

    result += line + '\n';
  });

  lineReader.on('close', () => {
    if (indent > 0) {
      error = true;
      console.error(chalk.red('ERR File "' + file + '" is missing a closing bracket \'}\'.'));
    }
    if (indent < 0) {
      error = true;
      console.error(chalk.red('ERR File "' + file + '" is missing an opening bracket \'{\'.'));
    }
    if (!error && !checkEqual(before, result)) {
      fs.writeFile(file, result, { encoding: 'utf8' }, function (err) {
        if (err) {
          return console.error(chalk.red(err));
        }
        console.log('Cleaned ' + chalk.green(file));
      });
    }
  });
}

function checkEqual (s1, s2) {
  if (s1 === s2) {
    return true;
  } else {
    return s1.replace(/[^a-zA-Z0-9 "{}]/g, '') === s2.replace(/[^a-zA-Z0-9 "{}]/g, '');
  }
}

walk('game/scripts/npc', cleanKVFile);
