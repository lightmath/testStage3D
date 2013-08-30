package
{
	import com.adobe.utils.AGALMiniAssembler;
	import com.adobe.utils.PerspectiveMatrix3D;
	import com.adobe.utils.Stats;
	import com.adobe.utils.movieMonitor;
	
	import flash.crypto.generateRandomBytes;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	[SWF(width="640", height="480",frameRate="60")]
	public class testStage3D extends Sprite
	{
		
		[Embed(source="texture.jpg")]
		private var myTextureBitmap:Class;
		
		private const swfWidth:int = 640;
		private const swfHeight:int = 480;
		private const textureSize:int = 512;
		
		private var context3D:Context3D;
		/**
		 * 用于渲染网格的着色器
		 */		
		private var shaderProgram:Program3D;
		/**
		 * 网格用到的顶点
		 */		
		private var vertexBuffer:VertexBuffer3D;
		/**
		 * 网格的顶点索引
		 */		
		private var indexBuffer:IndexBuffer3D;
		/**
		 * 用于定义网格模型的数据
		 */		
		private var meshVertexData:Vector.<Number>;
		/**
		 * 定义了每个顶点用到哪些数据的索引
		 */		
		private var meshIndexData:Vector.<uint>;
		/**
		 * 影响模型位置和相机角度的矩阵
		 */		
		private var projectionMatrix:PerspectiveMatrix3D = new PerspectiveMatrix3D();
		private var modelMatrix:Matrix3D = new Matrix3D();
		private var viewMatrix:Matrix3D = new Matrix3D();
		private var modelViewProjection:Matrix3D = new Matrix3D();
		
		private var t:Number = 0;
		private var myTextureData:Bitmap = new myTextureBitmap();
		private var myTexture:Texture;
		
		
		public function testStage3D()
		{
			if(stage != null)
			{
				init();
			}
			else
			{
				addEventListener(Event.ADDED_TO_STAGE, init);
			}
		}
		
		private function init(e:Event = null):void
		{
			if(hasEventListener(Event.ADDED_TO_STAGE))
				removeEventListener(Event.ADDED_TO_STAGE, init);
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, onContext3DCreate);
			stage.stage3Ds[0].requestContext3D();
		}
		
	
		private function onContext3DCreate(e:Event):void
		{
			removeEventListener(Event.ENTER_FRAME, enterFrame);
			var t:Stage3D = e.target as Stage3D;
			context3D = t.context3D;
			if(context3D == null)
			{
				trace("no 3D");
			}
			else
			{
				trace("hello world");
				context3D.enableErrorChecking = true;
				initData();
				
//				var anla:Stats = new Stats();
				var anla:movieMonitor = new movieMonitor();
				addChild(anla);
				anla.x = 10;
				anla.y = 20;
			}
		}
		
		private function initData():void
		{
			meshIndexData = Vector.<uint>
				([
					0,1,2,	0,2,3
				]);
			meshVertexData = Vector.<Number>
				([
					-1,-1,1,	0,0,	0,0,1,
					1,-1,1,		1,0,	0,0,1,
					1,1,1,		1,1,	0,0,1,
					-1,1,1,		0,1,	0,0,1
				]);
			context3D.configureBackBuffer(swfWidth, swfHeight, 0, true);
			
			var vertexShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			vertexShaderAssembler.assemble
			(
				Context3DProgramType.VERTEX,
				"m44 op, va0, vc0\n"+
				"mov v0, va0\n"+
				"mov v1, va1\n"
			);
			
			var fragmentShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			fragmentShaderAssembler.assemble
			(
				Context3DProgramType.FRAGMENT,
				"tex ft0,v1,fs0 <2d,repeat,miplinear>\n"+
				"mov oc, ft0\n"
			);
			
			shaderProgram = context3D.createProgram();
			shaderProgram.upload(vertexShaderAssembler.agalcode,fragmentShaderAssembler.agalcode);
			
			indexBuffer = context3D.createIndexBuffer(meshIndexData.length);
			indexBuffer.uploadFromVector(meshIndexData, 0, meshIndexData.length);
			
			vertexBuffer = context3D.createVertexBuffer(meshVertexData.length/8,8);
			vertexBuffer.uploadFromVector(meshVertexData, 0, meshVertexData.length/8);
			
			myTexture = context3D.createTexture(textureSize, textureSize, Context3DTextureFormat.BGRA, false);
			var ws:int = myTextureData.bitmapData.width;
			var hs:int = myTextureData.bitmapData.height;
			var level:int = 0;
			var tmp:BitmapData;
			var transform:Matrix = new Matrix();
			tmp = new BitmapData(ws,hs,true,0x0);
			while(ws>=1 && hs>=1)
			{
				tmp.draw(myTextureData.bitmapData, transform, null, null,null, true);
				myTexture.uploadFromBitmapData(tmp, level);
				transform.scale(0.5, 0.5);
				level++;
				ws>>=1;
				hs>>=1;
				if(hs && ws)
				{
					tmp.dispose();
					tmp = new BitmapData(ws, hs, true, 0x0);
				}
			}
			tmp.dispose();
			
			projectionMatrix.identity();
			projectionMatrix.perspectiveFieldOfViewRH(45, swfWidth/swfHeight, 0.01, 100);
			viewMatrix.identity();
			viewMatrix.appendTranslation(0,0,-4);
			
			addEventListener(Event.ENTER_FRAME, enterFrame);
		}
		
		private function enterFrame(e:Event):void
		{
			context3D.clear(0,0,0);
			context3D.setProgram(shaderProgram);
			
			modelMatrix.identity();
			modelMatrix.appendRotation(t*0.7, Vector3D.Y_AXIS);
			modelMatrix.appendRotation(t*0.6, Vector3D.X_AXIS);
			modelMatrix.appendRotation(t*1.0, Vector3D.Z_AXIS);
			modelMatrix.appendTranslation(0.0, 0.0, 0.0);
			modelMatrix.appendRotation(90,Vector3D.X_AXIS);
			
			t+=2;
			
			modelViewProjection.identity();
			modelViewProjection.append(modelMatrix);
			modelViewProjection.append(viewMatrix);
			modelViewProjection.append(projectionMatrix);
			
			context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, modelViewProjection, true);
			
			context3D.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			context3D.setVertexBufferAt(1, vertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_3);
			
			context3D.setTextureAt(0, myTexture);
			context3D.drawTriangles(indexBuffer, 0, meshIndexData.length/3);
			context3D.present();
		}
	}
}