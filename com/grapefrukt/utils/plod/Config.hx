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
	public var assets:Array<String>;
	
	public function new() { };
}
 
class Config {
	var data:BuildData;
	var _workingDir:String;
	var platforms:Map<String, PlatformConfig>;
	var json:Dynamic;
	
	var hostPlatform(get, never):PlatformConfig;
	
	public var dropbox(get, never):File;
	public var platformDropbox(get, never):File;
	public var build(get, never):File;
	
	var assetsPath:String;
	public var assetsDropbox(get, never):Array<File>;
	public var assetsLocal(get, never):Array<File>;
	public var assetsRaw(get, never):Array<String>;
	
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
		var p = hostPlatform;
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
	
	function get_assetsDropbox() {
		var assets = [];
		var paths = hostPlatform.assets;
		for (path in paths) assets.push(platformDropbox.resolveDirectory(path));
		return assets;
	}
	
	function get_assetsLocal() {
		var assets = [];
		var paths = hostPlatform.assets;
		for (path in paths) assets.push(workingDir.resolveDirectory(assetsPath).resolveDirectory(path));
		return assets;
	}
	
	function get_platformDropbox() return dropbox.resolvePath(Std.string(data.platform));
	function get_zip() return hostPlatform.zip;
	function get_scp() return hostPlatform.scp;
	function get_workingDir() return File.current.resolveDirectory(_workingDir);
	function get_assetsRaw() return hostPlatform.assets;
	function get_hostPlatform() return platforms.get(Std.string(PlatformHelper.hostPlatform));
	
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
		json = Json.parse(s);
		
		serverPath = Reflect.field(json, 'serverPath');
		assetsPath = Reflect.field(json, 'assetsPath');
		
		for (platform in Reflect.fields(json)) {
			var platformConfig = new PlatformConfig();
			var platformData = Reflect.field(json, platform);
			
			for (field in Type.getInstanceFields(PlatformConfig)) {
				Reflect.setField(platformConfig, field, Reflect.getProperty(platformData, field));
			}
			
			platforms.set(platform, platformConfig);
		}
		
		return true;
	}
	
}