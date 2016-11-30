package com.desktop.otsuka.slidelibrary.controller
{
	import com.desktop.otsuka.slidelibrary.view.LoginPanel;
	
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;

	public class ClinicalPathwaysLauncher extends EventDispatcher
	{
		public var process:NativeProcess;
		
		
		public function ClinicalPathwaysLauncher()
		{
			
		}
		
		public function launchAsNativeProcess():void
		{
			if(NativeProcess.isSupported)
			{
				setupAndLaunch();
			}
			else
			{
				trace("NativeProcess not supported.");
			}
		}
		
		public function setupAndLaunch():void
		{     
			var nativeProcessStartupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			//var file:File = File.applicationDirectory.resolvePath("test.py");
			//var file:File = File.documentsDirectory;
			// YourApp.app/Contents/MacOS/YourApp
			trace("wagwan 19");    
			// file = file.resolvePath("VA/clinicalchoicesapp_osx/clinical_choices.app");
			//new File("app:/assets/clinicalchoicesapp_win32/nw.exe"); 

			var file:File = File.applicationDirectory; 
			if ( LoginPanel.MAC_BUILD )
			{
				//file = file.resolvePath("assets/clinicalPathways/clinicalchoicesapp_osx/clinical_choices.app/Contents/MacOS/node-webkit");
				file = file.resolvePath("assets/clinicalPathways/mac/Clinical Pathways.app/Contents/MacOS/node-webkit");
				//file = file.resolvePath("assets/clinicalPathways/mac/Clinical Pathways.app");
			}else{
				//file = file.resolvePath("assets/clinicalPathways/clinicalchoicesapp_win32/nw.exe");
				file = file.resolvePath("assets/clinicalPathways/win/Clinical Pathways/Clinical Pathways.exe");
			}
			
			nativeProcessStartupInfo.executable = file;
			nativeProcessStartupInfo.workingDirectory = File.applicationDirectory;
			
			var processArgs:Vector.<String> = new Vector.<String>();
			processArgs[0] = "Keypoint";
			nativeProcessStartupInfo.arguments = processArgs;
			
			process = new NativeProcess();  
			process.start(nativeProcessStartupInfo);
			process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
			process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
			process.addEventListener(NativeProcessExitEvent.EXIT, onExit);
			process.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, onIOError);
			process.addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onIOError); 
		} 
		
		public function onOutputData(event:ProgressEvent):void
		{
			trace("Got: ", process.standardOutput.readUTFBytes(process.standardOutput.bytesAvailable)); 
		}
		
		public function onErrorData(event:ProgressEvent):void
		{
			trace("ERROR -", process.standardError.readUTFBytes(process.standardError.bytesAvailable)); 
		}
		
		public function onExit(event:NativeProcessExitEvent):void
		{
			trace("Process exited with ", event.exitCode);
			dispatchEvent(new SlidesEvent( SlidesEvent.EXTERNAL_APP_CLOSED));
		}
		
		public function onIOError(event:IOErrorEvent):void
		{
			trace(event.toString());
		}
	}
}