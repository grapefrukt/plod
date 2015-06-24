package com.grapefrukt.utils.plod;
import com.grapefrukt.utils.plod.Plod.BuildData;
import haxe.Json;
import lime.project.Platform;
import lime.tools.helpers.PlatformHelper;
import massive.sys.io.File;

/**
 * ...
 * @author Martin Jonasson (m@grapefrukt.com)
 */

private class PlatformConfig {
	public var dropbox:String;
	public var zip:String;
	public var scp:String;
	
	public function new() { };
}
 
class Config {
	var data:BuildData;
	var _workingDir:String;
	var platforms:Map<String, PlatformConfig>;
	
	public var dropbox(get, never):File;
	public var platformDropbox(get, never):File;
	public var build(get, never):File;
	
	public var workingDir(get, never):File;
	
	public var isSingleFile(get, never):Bool;
	public var useCompression(get, never):Bool;
		
	public var zip(get, never):String;
	public var scp(get, never):String;
	
	public var serverPath(default, null):String;
	
	public function new(workingDirectory:String) {
		_workingDir = workingDirectory;
	}
	
	function get_dropbox() {
		var p = platforms.get(Std.string(PlatformHelper.hostPlatform));
		return File.current.resolveDirectory(p.dropbox);
	}
	
	function get_build() {
		var p = switch (data.platform) {
			case Platform.ANDROID	: '${data.path}/android/bin/bin/${data.file}-release.apk';
			case Platform.WINDOWS	: '${data.path}/windows/cpp/bin';
			case Platform.MAC		: '${data.path}/mac64/cpp/bin';
			case Platform.LINUX		: '${data.path}/linux64/cpp/bin';
			default					: throw 'platform path not set';
		}
		
		return workingDir.resolvePath(p);
	}
	
	function get_isSingleFile() {
		return switch (data.platform) {
			case Platform.ANDROID	: true;
			default					: false;
		}
	}
	
	function get_useCompression() {
		return switch (data.platform) {
			case Platform.ANDROID	: false;
			default					: true;
		}
	}
		
	function get_platformDropbox() {
		return dropbox.resolvePath(Std.string(data.platform));
	}
	
	function get_zip() {
		return platforms.get(Std.string(PlatformHelper.hostPlatform)).zip;
	}
	
	function get_scp() {
		return platforms.get(Std.string(PlatformHelper.hostPlatform)).scp;
	}
	
	function get_workingDir() {
		return File.current.resolveDirectory(_workingDir);
	}

	public function setData(data:BuildData) {
		this.data = data;
	}
	
	public function parse() {
		var f = workingDir.resolveFile('plod.json');
		if (!f.exists) {
			Plod.error('unable to find plod.json');
			return false;
		}
		
		platforms = new Map();
		
		var s = f.readString();
		var j = Json.parse(s);
		
		serverPath = Reflect.field(j, 'serverPath');
		
		for (platform in Reflect.fields(j)) {
			var platformConfig = new PlatformConfig();
			var platformData = Reflect.field(j, platform);
			
			for (field in Type.getInstanceFields(PlatformConfig)) {
				Reflect.setField(platformConfig, field, Reflect.getProperty(platformData, field));
			}
			
			platforms.set(platform, platformConfig);
		}
		
		return true;
	}
	
}