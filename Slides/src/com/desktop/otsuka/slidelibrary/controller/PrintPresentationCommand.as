package com.desktop.otsuka.slidelibrary.controller
{
	import com.desktop.otsuka.slidelibrary.view.PopupAlert;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.printing.PrintJob;
	import flash.printing.PrintJobOptions;
	import flash.printing.PrintJobOrientation;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	import flashx.textLayout.formats.TLFTypographicCase;
	
	import mx.controls.HTML;
	import mx.managers.PopUpManager;
	
	import spark.components.TextArea;
	import spark.utils.TextFlowUtil;
	
	public class PrintPresentationCommand extends EventDispatcher
	{
		
		private const LARGE_MARGIN_BOTTOM:int = 24;
		private const THUMBNAIL_WIDTH:int = 250;
		private const THUMBNAIL_HEIGHT:int = 250;
		private const THUMBNAIL_MARGIN_RIGHT:int = 20;
		private const THUMBNAIL_MARGIN_BOTTOM:int = 18;
		
		
		private var _presentationName:String;
		private var _slidesToPrint:Array;
		private var _slideNotes:Array;
		private var _currentImage:Bitmap;
		private var _parentDisplayObject:DisplayObject;
		
		//private var _notesTF:TextField;
		//private var _notesFont:VerdanaRegular;
		//private var _notesTextFormat:TextFormat;
		
		private var _printOptionsPopup:PopupAlert;
		
		public function PrintPresentationCommand(target:IEventDispatcher=null)
		{
			super(target);
		}
		public function init(presentationName:String, slidesToPrint:Array, parentDisplayObject:DisplayObject, slideNotes:Array):void{
			
			_presentationName = presentationName;
			_slidesToPrint = slidesToPrint;
			_parentDisplayObject = parentDisplayObject;
			_slideNotes = slideNotes;
			
		}
		public function doThePrint():void{
			
			// make a popup 
			// you can print big
			// or you can print small
			
			
			/*
			==============================
			NOT USED ANYMORE
			===========================
			
			_printOptionsPopup = PopUpManager.createPopUp(_parentDisplayObject ,PopupAlert,true) as PopupAlert;
			_printOptionsPopup.setWidthAndHeight(480,300);				
			_printOptionsPopup.titleLabel.text = "Print Options";
			_printOptionsPopup.bodyTextArea.text = "Please indicate a range of slides to print. For example: '1-2, 5-7' will print slides 1, 2, 5, 6, 7."; 
			_printOptionsPopup.inputTI.text = "1-" + _slidesToPrint.length.toString();
			_printOptionsPopup.inputTI.visible = true;
			_printOptionsPopup.inputTI.setFocus();
			_printOptionsPopup.inputTI.y = 200;
			_printOptionsPopup.yesButton.label = "Full Size";
			_printOptionsPopup.noButton.visible = true;
			_printOptionsPopup.noButton.label = "Thumbnails";
			_printOptionsPopup.noButton.width = 115;
			
			_printOptionsPopup.yesButton.addEventListener(MouseEvent.CLICK, function(e:Event):void{					
				//fullsize
				var popupInputText:String = (e.target.parent.parent as PopupAlert).inputTI.text;
				PopUpManager.removePopUp(_printOptionsPopup);
				printFullSlidesOptionHandler(popupInputText);
			});
			_printOptionsPopup.noButton.addEventListener(MouseEvent.CLICK, function(e:Event):void{			
				//thumbnails
				var popupInputText:String = (e.target.parent.parent as PopupAlert).inputTI.text;
				PopUpManager.removePopUp(_printOptionsPopup);
				printThumbnailsOptionHandler(popupInputText);				
			});
			PopUpManager.centerPopUp(_printOptionsPopup);
			*/
		}
		
		
		
		private function printThumbnailsOptionHandler(popupInputText:String):void
		{
			
			var rangeString:String = popupInputText;
			trace( "Input: " + rangeString );
			
			var range:Array = parseRange(rangeString);
			if( range.length == 1 && range[0] == 0 ) { 
			trace("Invalid range.");			
			return;
			}
			
			trace("Parsed range: " + range);			
			
			var printJob:PrintJob = new PrintJob();
			printJob.jobName = _presentationName;
			
			var printJobOptions:PrintJobOptions = new PrintJobOptions();
			//printJobOptions.printAsBitmap = true; //really slow...
			
			if( printJob.start() ) { 
				
				if( _slidesToPrint.length && range.length ) { //if there are any images to show...
					
					var total:uint = 1;
					var index:uint = 0;
					var thumbsPerRow:int = 2; //Math.floor( printJob.pageWidth / (THUMBNAIL_WIDTH + THUMBNAIL_MARGIN_RIGHT));
					var thumbsPerColumn:int = 3; 
					var totalPerPage:int = thumbsPerRow * thumbsPerColumn;
					var pageAdded:Boolean = false;
					
					var sprite:Sprite = new Sprite();
					
					for( var i:uint = 0; i < range.length; i++ ) { //only print the ones the user specified...
						
						var z:int = (range[i] as int) - 1 ;
						var image:Bitmap = _slidesToPrint[z];
						
						_currentImage = image;
						_currentImage.width = THUMBNAIL_WIDTH;
						_currentImage.scaleY = _currentImage.scaleX;
						_currentImage.smoothing = true;
						
						_currentImage.x = (index % thumbsPerRow) * (THUMBNAIL_WIDTH + THUMBNAIL_MARGIN_RIGHT);
						_currentImage.y = Math.floor( index / thumbsPerRow ) * (THUMBNAIL_HEIGHT + THUMBNAIL_MARGIN_BOTTOM);
						
						sprite.addChild(_currentImage);
						
						pageAdded = false;
						
						if( index == (totalPerPage - 1) ) { 
							try { 
								
								printJob.addPage( sprite, null, printJobOptions ); //printJob.printableArea
							}
							catch( err:Error ) { 
								trace(err, err.message);
							}
							
							trace("adding page of thumbnails");
							
							pageAdded = true;
							sprite = new Sprite();
							index = 0; //reset page
						}
						else { 
							index++;
						}
						
						trace(" added image " + index + " total = " + total);
						
						total++;
					}
					
					if( ! pageAdded ) { //add the final page
						try { 
							printJob.addPage( sprite, null, printJobOptions ); //printJob.printableArea
						}
						catch( err:Error ) { 
							trace(err, err.message);
						}
						
						trace("adding page of thumbnails");
					}
				}
				else { //nothing to print?
					return; //?
				}
				
				//printJob.addEventListener //functionality doesn't exist
				
				try { 
					printJob.send();
				}
				catch( err:Error ) { 
					trace(err, err.message);
				}
				
				sprite = null;
				printJob = null; 
			}
			else { 
				//user cancelled print
			}
			
		}
		
		private function printFullSlidesOptionHandler(popupInputText:String):void
		{
//			_notesTextFormat = new TextFormat();//(_notesFont.fontName, 14, 0x0, false);
//			_notesTextFormat.size = 14;
//			
//			_notesTextFormat.align = TextFormatAlign.LEFT;
			
			var rangeString:String = popupInputText;
			trace( "Input: " + rangeString );
			
			var range:Array = parseRange(rangeString);
			if( range.length == 1 && range[0] == 0 ) { 
				trace("Invalid range.");
				return;
			}
			
			trace("Parsed range: " + range);
			
			var printJob:PrintJob = new PrintJob();
			printJob.jobName = _presentationName;
			printJob.orientation = PrintJobOrientation.LANDSCAPE;
			
			var printJobOptions:PrintJobOptions = new PrintJobOptions();
			//printJobOptions.printAsBitmap = true; //really slow...
			
			if( printJob.start() ) { 
				
				if( _slidesToPrint.length > 0 && range.length ) { //if there are any images to show...
					
					var total:uint = 1;
					var index:uint = 0;
					var totalPerPage:int = 1;
					var pageAdded:Boolean = false;
					
					var imageRect:Rectangle = printJob.printableArea;
					imageRect.width = Math.floor(imageRect.width * 0.66);
					
					var notesRect:Rectangle = printJob.printableArea;
					notesRect.width = Math.floor(notesRect.width * 0.33);
					notesRect.x = (notesRect.x + printJob.printableArea.width) - notesRect.width;
					
					var sprite:Sprite = new Sprite();
					
//					_notesTF = new TextField();
//					_notesTF.autoSize = TextFieldAutoSize.LEFT;
//					_notesTF.wordWrap = true;
//					_notesTF.multiline = true;
//					_notesTF.x = notesRect.x;
//					_notesTF.y = notesRect.y;
//					_notesTF.width = notesRect.width;
//					_notesTF.height = notesRect.height;
					
//					var myFormat:TextFormat = new TextFormat();
//					myFormat.size = 10;
//					
//					_notesTF.defaultTextFormat = myFormat;
					
					var htmlPage:HTML = new HTML();
					htmlPage.width = notesRect.width;
					htmlPage.height = notesRect.height;
					htmlPage.x = notesRect.x;
					htmlPage.y = notesRect.y;
					
					for( var i:uint = 0; i < range.length; i++ ) { //only print the ones the user specified...
						
						var z:int = (range[i] as int) - 1 ;
						var image:Bitmap = _slidesToPrint[z];
						
						_currentImage = image;
						fitIntoRect( _currentImage, imageRect, false, true );
						
						_currentImage.smoothing = true;
						
						_currentImage.x = imageRect.x; //0; //(printJob.pageWidth * 0.5) - (_currentImage.width * 0.5);
						_currentImage.y = imageRect.y; //( i%2 == 0 ) ? 0 : (printJob.pageHeight * 0.5);
						
						sprite.addChild(_currentImage);
						
						
						//_notesTF.text = _slideNotes[z] as String;
						htmlPage.htmlText = _slideNotes[z] as String;						
						
//						try
//						{
//							_notesTF.textFlow = TextFlowUtil.importFromString(_notesTF.text);
//						}
//						catch (e:Error)
//						{
//							trace("something is wrong with the notes on this slide");
//						}
						
						//trace("notes: " + _notesTF.text);
						
						//sprite.addChild(_notesTF);
						sprite.addChild(htmlPage);
						
						pageAdded = false;
						
						if( index == (totalPerPage - 1) ) { 
							try { 
								printJob.addPage( sprite, null, printJobOptions ); //printJob.printableArea
							}
							catch( err:Error ) { 
								trace(err, err.message);
							}
							
							trace("adding page of thumbnails");
							
							pageAdded = true;
							sprite = new Sprite();
							index = 0; //reset page
						}
						else { 
							index++;
						}
						
						trace(" added image " + index + " total = " + total);
						
						total++;
					}
					
					if( ! pageAdded ) { //add the final page
						try { 
							printJob.addPage( sprite, null, printJobOptions ); //printJob.printableArea
						}
						catch( err:Error ) { 
							trace(err, err.message);
						}
						
						trace("adding page of thumbnails");
					}
				}
				else { //nothing to print?
					return; //?
				}
				
				//printJob.addEventListener //functionality doesn't exist
				
				try { 
					printJob.send();
				}
				catch( err:Error ) { 
					trace(err, err.message);
				}
				
				sprite = null;
				printJob = null; 
			}
			else { 
				//user cancelled print
			}
			
		}
		
		
		private function parseRange(rangeString:String):Array
		{
			var range:Array = [];
			
			rangeString.replace(" ", "");
			var ranges:Array = rangeString.split(",");
			
			for each( var test:String in ranges ) { 
				if( (test.indexOf("-") > -1) ) { //grab the values inbetween
					var splitTest:Array = test.split("-");
					var first:int = int(splitTest[0]);
					var last:int = int(splitTest[1]);
					
					//add the inbetweens
					for( var i:int = first; i < last; i++ ) { 
						range[range.length] = i;
					}
					
					//add the last
					range[range.length] = last;
				}
				else { //just add it.
					range[range.length] = int(test);
				}
			}
			
			return range;
		}
		
		public function printSingleSlidezzz(slideImage:Bitmap, slideNotes:String):void{
			

			
//			_notesTextFormat = new TextFormat();//(_notesFont.fontName, 14, 0x0, false);
//			_notesTextFormat.size = 14;
//			
//			_notesTextFormat.align = TextFormatAlign.LEFT;
			
			var printJob:PrintJob = new PrintJob();
			printJob.jobName = _presentationName;
			printJob.orientation = PrintJobOrientation.LANDSCAPE;
			
			var printJobOptions:PrintJobOptions = new PrintJobOptions();
			//printJobOptions.printAsBitmap = true; //really slow...
			
			if( printJob.start() ) { 
				
							
					var total:uint = 1;
					var index:uint = 0;
					var totalPerPage:int = 1;
					var pageAdded:Boolean = false;
					
					var imageRect:Rectangle = printJob.printableArea;
					imageRect.width = Math.floor(imageRect.width * 0.74);
					
					var notesRect:Rectangle = printJob.printableArea;
					notesRect.width = Math.floor(notesRect.width * 0.24);
					notesRect.x = (notesRect.x + printJob.printableArea.width) - notesRect.width;
					
					var sprite:Sprite = new Sprite();
					
//					_notesTF = new TextField();
//					_notesTF.autoSize = TextFieldAutoSize.LEFT;
//					_notesTF.wordWrap = true;
//					_notesTF.multiline = true;
//					_notesTF.x = notesRect.x;
//					_notesTF.y = notesRect.y;
//					_notesTF.width = notesRect.width;
//					_notesTF.height = notesRect.height;
					
					var htmlPage:HTML = new HTML();
					htmlPage.width = notesRect.width;
					htmlPage.height = notesRect.height;
					htmlPage.x = notesRect.x;
					htmlPage.y = notesRect.y;
					
					
					
		
						
						var image:Bitmap = slideImage;
						
						_currentImage = image;
						fitIntoRect( _currentImage, imageRect, false, true );
						
						_currentImage.smoothing = true;
						
						_currentImage.x = imageRect.x; //0; //(printJob.pageWidth * 0.5) - (_currentImage.width * 0.5);
						_currentImage.y = imageRect.y; //( i%2 == 0 ) ? 0 : (printJob.pageHeight * 0.5);
						
						sprite.addChild(_currentImage);
						
						
						//_notesTF.text = slideNotes as String; 
						htmlPage.htmlText = slideNotes as String;
						//						try
						//						{
						//							_notesTF.textFlow = TextFlowUtil.importFromString(_notesTF.text);
						//						}
						//						catch (e:Error)
						//						{
						//							trace("something is wrong with the notes on this slide");
						//						}
						
						//trace("notes: " + _notesTF.text);
						
						//sprite.addChild(_notesTF);
						sprite.addChild(htmlPage);
						
						pageAdded = false;
						
						if( index == (totalPerPage - 1) ) { 
							try { 
								printJob.addPage( sprite, null, printJobOptions ); //printJob.printableArea
							}
							catch( err:Error ) { 
								trace(err, err.message);
							}
							
							trace("adding page of thumbnails");
							
							pageAdded = true;
							sprite = new Sprite();
							index = 0; //reset page
						}
						else { 
							index++;
						}
						
						trace(" added image " + index + " total = " + total);
						
						total++;
					
					
					if( ! pageAdded ) { //add the final page
						try { 
							printJob.addPage( sprite, null, printJobOptions ); //printJob.printableArea
						}
						catch( err:Error ) { 
							trace(err, err.message);
						}
						
						trace("adding page of thumbnails");
					}
				
				
				
				//printJob.addEventListener //functionality doesn't exist
				
				try { 
					printJob.send();
				}
				catch( err:Error ) { 
					trace(err, err.message);
				}
				
				sprite = null;
				printJob = null; 
			}
			else { 
				//user cancelled print
			}
		}
		
		
		public function printSingleSlide(slideImage:Bitmap, slideNotes:String,htmlBox:HTML):void{
			
			var printJob:PrintJob = new PrintJob();
			printJob.jobName = _presentationName;
			printJob.orientation = PrintJobOrientation.LANDSCAPE;
			
			var printJobOptions:PrintJobOptions = new PrintJobOptions();
			
			if( printJob.start() ) { 
				
				
				var total:uint = 1;
				var index:uint = 0;
				var totalPerPage:int = 1;
				var pageAdded:Boolean = false;
				
				var imageRect:Rectangle = printJob.printableArea;
				imageRect.width = Math.floor(imageRect.width * 0.74);
				
				var notesRect:Rectangle = printJob.printableArea;
				notesRect.width = Math.floor(notesRect.width * 0.24);
				notesRect.x = (notesRect.x + printJob.printableArea.width) - notesRect.width;
				
				var sprite:Sprite = new Sprite();
				
				
				
//				var htmlPage:HTML = new HTML();
//				htmlPage.width = 500;
//				htmlPage.height = 500;
//				htmlPage.x = 10;
//				htmlPage.y = 10;
				
				
				
				
				
				
				
				var image:Bitmap = slideImage;
				
			//	_currentImage = image;
//				fitIntoRect( _currentImage, imageRect, false, true );
//				
//				_currentImage.smoothing = true;
//				
//				_currentImage.x = imageRect.x; //0; //(printJob.pageWidth * 0.5) - (_currentImage.width * 0.5);
//				_currentImage.y = imageRect.y; //( i%2 == 0 ) ? 0 : (printJob.pageHeight * 0.5);
//				
//				sprite.addChild(_currentImage);
				
				
				//_notesTF.text = slideNotes as String; 
				//htmlPage.htmlText = slideNotes as String;
				//						try
				//						{
				//							_notesTF.textFlow = TextFlowUtil.importFromString(_notesTF.text);
				//						}
				//						catch (e:Error)
				//						{
				//							trace("something is wrong with the notes on this slide");
				//						}
				
				//trace("notes: " + _notesTF.text);
				
				//sprite.addChild(_notesTF);
				//sprite.addChild(htmlPage);
				//sprite.addChild(htmlBox);
				
				printJob.addPage( htmlBox, null, printJobOptions ); //printJob.printableArea
						//printJob.addPage( sprite, null, printJobOptions ); //printJob.printableArea
				
				
				try { 
					printJob.send();
				}
				catch( err:Error ) { 
					trace(err, err.message);
				}
				
				sprite = null;
				printJob = null; 
			}
			else { 
				//user cancelled print
			}
		}
		
		
		
		
		
		private function fitIntoRect( displayObject:DisplayObject, rectangle:Rectangle, fillRect:Boolean = true, applyTransform:Boolean = true ):Matrix //align:String = "C", 
		{
			
			//			if ( rectangle.x == 0 )
			//			{
			//				trace("debugging - error - wrong image position");
			//			}
			
			var matrix : Matrix = new Matrix();
			
			var wD : Number = displayObject.width / displayObject.scaleX;
			var hD : Number = displayObject.height / displayObject.scaleY;
			
			var wR : Number = rectangle.width;
			var hR : Number = rectangle.height;
			
			var sX : Number = wR / wD;
			var sY : Number = hR / hD;
			
			var rD : Number = wD / hD;
			var rR : Number = wR / hR;
			
			var sH : Number = fillRect ? sY : sX;
			var sV : Number = fillRect ? sX : sY;
			
			var s : Number = rD >= rR ? sH : sV;
			//var w : Number = wD * s;
			//var h : Number = hD * s;
			
			//var tX : Number = 0.0;
			//var tY : Number = 0.0;
			
			//tX = 0.0; //LEFT, TOP_LEFT, BOTTOM_LEFT
			//tY = 0.0; //TOP, TOP_LEFT, TOP_RIGHT
			//tX = w - wR; //RIGHT, TOP_RIGHT, BOTTOM_RIGHT
			//tY = h - hR; //BOTTOM, BOTTOM_LEFT, BOTTOM_RIGHT
			//tX = 0.5 * (w - wR);
			//tY = 0.5 * (h - hR);
			
			//trace("TRANSLATE: " + (rectangle.left - tX), (rectangle.top - tY));
			
			matrix.scale(s, s);
			//matrix.translate(rectangle.left - tX, rectangle.top - tY);
			
			if(applyTransform) displayObject.transform.matrix = matrix;
			
			return matrix;
		}
	}
}

/*
		
		
	
			
				
				
				


		
		
		
	}
}*/