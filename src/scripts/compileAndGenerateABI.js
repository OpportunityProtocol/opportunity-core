const path = require('path');
const fs = require('fs-extra');

const solc = require('solc');

const buildPath = path.resolve('../test', 'ganache', 'contracts');
const contractsFolderPath = path.resolve('../contracts', 'exchange');
const librariesFolderPath = path.resolve('../contracts', 'libraries');
const controlFolderPath = path.resolve('../contracts', 'control');

const createBuildFolder = () => {
	fs.emptyDirSync(buildPath);
}

const buildSources = () => {
    const sources = {};
    const contractsFiles = fs.readdirSync(contractsFolderPath);
	const libraryFiles = fs.readdirSync(librariesFolderPath);
	const controlFiles = fs.readdirSync(controlFolderPath);

    contractsFiles.forEach(file => {
		const contractFullPath = path.resolve(contractsFolderPath, file)
      sources[file] = {
        content: fs.readFileSync(contractFullPath, 'utf8')
      };
    });

	libraryFiles.forEach(file => {
		const contractFullPath = path.resolve(librariesFolderPath, file)
      sources[file] = {
        content: fs.readFileSync(contractFullPath, 'utf8')
      };
    });

	controlFiles.forEach(file => {
		const contractFullPath = path.resolve(controlFolderPath, file)
      sources[file] = {
        content: fs.readFileSync(contractFullPath, 'utf8')
      };
    });
    
    return sources;
  }

  const input = {
	language: 'Solidity',
	sources: buildSources(),
	settings: {
		outputSelection: {
			'*': {
				'*': [ 'abi', 'evm.bytecode' ]
			}
		}
	}
}

const compileContracts = () => {
	const compiledContracts = JSON.parse(solc.compile(JSON.stringify(input))).contracts;

	console.log(solc.compile(JSON.stringify(input)))
	for (let contract in compiledContracts) {
		console.log(contract)
		for(let contractName in compiledContracts[contract]) {
			console.log(contractName)
			fs.outputJsonSync(
				path.resolve(buildPath, `${contractName}.json`),
				compiledContracts[contract][contractName],
				{
					spaces: 2
				}
			)
		}
	}
}


(function run () {
	createBuildFolder();
	compileContracts();
})();