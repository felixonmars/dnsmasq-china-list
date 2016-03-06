const dns = require('dns');

var lineReader = require('readline').createInterface({
  input: require('fs').createReadStream('accelerated-domains.china.conf')
});

lineReader.on('line', function (line) {
	try{
		var s = line.match(/server=\/(.*)\//i)[1];
		dns.lookup(s, function(err, addresses, family) {
			if(err){
	  			console.log("#",line);
			}else{
  				console.log(line);//console.log(line.replace(/^(#|\s)*/,""));
  			}
		});
	}catch(err){
		console.log("##",line);
	}
});

