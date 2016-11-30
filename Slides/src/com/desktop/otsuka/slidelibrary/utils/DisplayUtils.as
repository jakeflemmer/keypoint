package com.desktop.otsuka.slidelibrary.utils
{
	/**
	 * uk.soulwire.utils.display.DisplayUtils
	 * 
	 * @version v1.0
	 * @since May 26, 2009
	 * 
	 * @author Justin Windle
	 * @see http://blog.soulwire.co.uk
	 * 
	 * About DisplayUtils
	 * 
	 * DisplayUtils is a set of static utility methods for dealing 
	 * with DisplayObjects
	 * 
	 * Licensed under a Creative Commons Attribution 3.0 License
	 * http://creativecommons.org/licenses/by/3.0/
	 */
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.PixelSnapping;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class DisplayUtils 
	{	
		public static const BOTTOM : String = "B";
		public static const BOTTOM_LEFT : String = "BL";
		public static const BOTTOM_RIGHT : String = "BR";
		public static const LEFT : String = "L";
		public static const MIDDLE : String = "C";
		public static const RIGHT : String = "R";
		public static const TOP : String = "T";
		public static const TOP_LEFT : String = "TL";
		public static const TOP_RIGHT : String = "TR";
		
		//---------------------------------------------------------------------------
		//------------------------------------------------------------ PUBLIC METHODS
		
		/**
		 * Fits a DisplayObject into a rectangular area with several options for scale 
		 * and alignment. This method will return the Matrix required to duplicate the 
		 * transformation and can optionally apply this matrix to the DisplayObject.
		 * 
		 * @param displayObject
		 * 
		 * The DisplayObject that needs to be fitted into the Rectangle.
		 * 
		 * @param rectangle
		 * 
		 * A Rectangle object representing the space which the DisplayObject should fit into.
		 * 
		 * @param fillRect
		 * 
		 * Whether the DisplayObject should fill the entire Rectangle or just fit within it. 
		 * If true, the DisplayObject will be cropped if its aspect ratio differs to that of 
		 * the target Rectangle.
		 * 
		 * @param align
		 * 
		 * The alignment of the DisplayObject within the target Rectangle. Use a constant from 
		 * the DisplayUtils class.
		 * 
		 * @param applyTransform
		 * 
		 * Whether to apply the generated transformation matrix to the DisplayObject. By setting this 
		 * to false you can leave the DisplayObject as it is but store the returned Matrix for to use 
		 * either with a DisplayObject's transform property or with, for example, BitmapData.draw()
		 */
		
		public static function fitIntoRect( displayObject:DisplayObject, rectangle:Rectangle, fillRect:Boolean = true, applyTransform:Boolean = true ):Matrix //align:String = "C", 
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
		
		/**
		 * Creates a thumbnail of a BitmapData. The thumbnail can be any size as 
		 * the copied image will be scaled proportionally and cropped if necessary 
		 * to fit into the thumbnail area. If the image needs to be cropped in order 
		 * to fit the thumbnail area, the alignment of the crop can be specified
		 * 
		 * @param image
		 * 
		 * The source image for which a thumbnail should be created. The source 
		 * will not be modified
		 * 
		 * @param width
		 * 
		 * The width of the thumbnail
		 * 
		 * @param height
		 * 
		 * The height of the thumbnail
		 * 
		 * @param align
		 * 
		 * If the thumbnail has a different aspect ratio to the source image, although 
		 * the image will be scaled to fit along one axis it will be necessary to crop 
		 * the image. Use this parameter to specify how the copied and scaled image should 
		 * be aligned within the thumbnail boundaries. Use a constant from the Alignment 
		 * enumeration class
		 * 
		 * @param smooth
		 * 
		 * Whether to apply bitmap smoothing to the thumbnail
		 */
		
		public static function createThumb( image:BitmapData, width:int, height:int, smooth:Boolean = true, transparent:Boolean = true, fillRect:Boolean = true ):Bitmap //align:String = "C", 
		{
			var source : Bitmap = new Bitmap(image);
			var thumbnail : BitmapData = new BitmapData(width, height, transparent, 0x0);
			
			thumbnail.draw(image, fitIntoRect(source, thumbnail.rect, fillRect, false), null, null, null, smooth); // align,
			source = null;
			
			return new Bitmap(thumbnail, PixelSnapping.AUTO, smooth);
		}
		
		public static function cropBitmapData(sourceBitmapData:BitmapData, startPoint:Point, width:Number, height:Number):BitmapData
		{
			var croppedBD:BitmapData = new BitmapData(width, height);
			croppedBD.copyPixels(sourceBitmapData, new Rectangle(startPoint.x, startPoint.y, width, height), new Point(0, 0));
			return croppedBD.clone();
			croppedBD.dispose();
		}
	}
}
