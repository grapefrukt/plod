package com.grapefrukt.utils.plod;
import haxe.Json;
import lime.project.HXProject;
import massive.sys.io.File;
import sys.FileSystem;
import sys.io.Process;

/**
 * ...
 * @author Martin Jonasson (m@grapefrukt.com)
 */
class Plod {
	
	static var data:BuildData;
	static var config:Config;
	static var tmp:File;
		
	public static function main() {
		var workingDirectory = Sys.args().pop();
		config = new Config(workingDirectory);
		
		if (!config.parse()) return;
		
		print('PLOD');
		print('');
		
		data = new BuildData(config);
		if (!data.parse()) return;
		
		config.setData(data);
		
		tmp = File.createTempDirectory();
		
		var secondsAgo = Math.round((Date.now().getTime() - data.date.getTime()) / 1000);
		
		print('project:    ${data.file}');
		print('platform:   ${data.platform}');
		print('host:       ${data.host}');
		print('build date: ${data.date} ($secondsAgo seconds ago)');
		print('version:    ${data.tag}');
		print('debug:      ${data.debug}');
		print('');
		
		toDropbox();
		toWebsite();
		
		tmp.deleteDirectory(true);
	}
	
	static private function toDropbox() {
		print('Copying to Dropbox... ', false);
		copyBuild(config.platformDropbox);
		fixExecutable(config.platformDropbox);
		print('completed!');
	}
	
	static function copyBuild(into:File) {
		into.createDirectory();
		config.build.copyTo(into, true, null, false);
		config.workingDir.resolveFile('build.json').copyTo(into);
	}
	
	static function zip(silent:Bool = false) {
		if (!silent) print('Compressing... ', false);
		
		// copy the build into the temp folder
		copyBuild(tmp);
		fixExecutable(tmp);

		// move into this folder and zip *
		Sys.setCwd(tmp.toString());

		var p = new Process(config.zip, ['a', '${data.file}.zip', '*']);

		// read the exit code here to block the process
		var result = checkProcessResult(p, silent);
		
		// delete everything but the zipfile and the build.json
		tmp.deleteDirectoryContents(new EReg('(${data.file}.zip|build.json)', 'g'), true);
		
		// move back to the "home" folder
		Sys.setCwd(config.workingDir.toString());
		
		return result;
	}
	
	static function toWebsite() {

		print('Uploading to website... ', false);
		if (!config.useCompression) copyBuild(tmp);
		else zip(true);
		
		Sys.setCwd(tmp.toString());
		
		var files = tmp.getDirectoryListing();
		var args = [ for (file in files) file.fileName.toString()];
		args.push(replaceTemplates(config.serverPath));
		
		var p = new Process(config.scp, args);
		Sys.setCwd(config.workingDir.toString());
		
		return checkProcessResult(p);
	}

	static function fixExecutable(path:File) {
		if (data.platform == 'mac' && data.host == 'mac') {
			Sys.setCwd(path.toString());
			var p = new Process('chmod', ['+x', '${data.file}.app/Contents/MacOS/${data.file}']);
			var result = checkProcessResult(p, true);
		}
	}
	
	static function replaceTemplates(string:String) {
		for (field in Type.getInstanceFields(BuildData)) {
			string = StringTools.replace(string, "$" + field, Reflect.getProperty(data, field));
		}
		return string;
	}
	
	static function checkProcessResult(p:Process, silent:Bool = false) {
		var exitCode = p.exitCode();
		
		if (exitCode == 0) {
			p.close();
			if (!silent) print('completed!');
			return true;
		}
		
		if (!silent) print('failed!');
		var b = p.stderr.readAll();
		print('stderr: ' + b.getString(0, b.length));
		b = p.stdout.readAll();
		print('stdout: ' + b.getString(0, b.length));
		
		p.close();
		return false;
	}
	
	static public function print(string:String, linebreak:Bool = true) {
		linebreak ? Sys.println(string) : Sys.print(string);
	}
	
	static public function error(error:String) {
		print('error: $error');
	}
	
}

class BuildData {
	
	var config			:Config;
	public var date		:Date = null;
	public var host		:String = '';
	public var platform	:String = '';
	public var tag		:String = '';
	public var path		:String = '';
	public var file		:String = '';
	public var debug	:Bool = false;
	
	public function new(config:Config) { 
		this.config = config;
	}
	
	public function parse() {
		var f = config.workingDir.resolveFile('build.json');
		if (!f.exists) {
			Plod.error('error: build.json not found in directory.');
			return false;
		}
		
		var s = f.readString();
		var j = Json.parse(s);
		
		date = 		j.date != null ? Date.fromString(j.date) : null;
		host = 		j.host;
		platform = 	j.platform;
		tag = 		j.tag;
		path = 		j.path;
		file = 		j.file;
		debug = 	j.debug == 'true';
		
		return true;
	}
}