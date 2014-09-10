package
{
	import com.adobe.utils.AGALMiniAssembler;
	import com.adobe.utils.PerspectiveMatrix3D;
	
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
	
	/**
	 * 
	 * @author licheng
	 * 2014-9-10下午12:40:26
	 */	
	[SWF(width="640", height="480", frameRate="60", backgroundCorlor="0xCCFF00")]
	public class Stage3dGame01 extends Sprite
	{
		
		private const swfWidth:int = 640;
		private const swfHeight:int = 480;
		private const textureSize:int = 512;
		/**
		 * 舞台上的3D图形窗口
		 */		
		private var context3D:Context3D;
		/**
		 * 用于渲染我们网格的着色器
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
		
		[Embed (source="texture.jpg")]
		private var myTextureBitmap:Class;
		private var myTextureData:Bitmap = new myTextureBitmap();
		private var myTexture:Texture;
		
		public function Stage3dGame01()
		{
			super();
			if(stage != null)
				init();
			else
				addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event=null):void
		{
			if(hasEventListener(Event.ADDED_TO_STAGE))
			{
				removeEventListener(Event.ADDED_TO_STAGE, init);
			}
			
			stage.frameRate = 60;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, onContext3DCreate);
			stage.stage3Ds[0].requestContext3D();
			
		}
		
		private function onContext3DCreate(e:Event):void
		{
			if(hasEventListener(Event.CONTEXT3D_CREATE))
			{
				stage.stage3Ds[0].removeEventListener(Event.CONTEXT3D_CREATE, onContext3DCreate);
			}
//			获取当前环境
			var t:Stage3D = e.target as Stage3D;
			context3D = t.context3D;
			
			if(context3D == null)
			{
				trace("没有3D环境可用");
				return;
			}
			
			context3D.enableErrorChecking = true;
			initData();
			
//			3D后备缓冲区的像素尺寸
			context3D.configureBackBuffer(swfWidth, swfHeight, 0, true);
			
//			一个简单的顶点着色器，它实现了3D变换 
			var vertexShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			vertexShaderAssembler.assemble
				(
				Context3DProgramType.VERTEX,
//				4x4矩阵乘以相机角度
				"m44 op, va0, vc0\n"+
//				告诉片段着色器x,y,z的值
				"mov v0, va0\n"+
//				告诉片段着色器u，v的值
				"mov v1, va1\n"
				);
			
//			一个简单的片段着色器，使用顶点位置和纹理颜色
			var fragmentShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			fragmentShaderAssembler.assemble
				(
				Context3DProgramType.FRAGMENT,
//				使用存于v1中的u，v坐标， 从纹理fs0中取得纹理的颜色
				"tex ft0, v1, fs0 <2d, repeat,miplinear>\n"+
//				将结果输出
				"mov oc, ft0\n"
				);
			
//			将两者混合成着色器， 随后上传给GPU
			shaderProgram = context3D.createProgram();
			shaderProgram.upload(vertexShaderAssembler.agalcode,
								fragmentShaderAssembler.agalcode);
			
//			上传网格索引
			indexBuffer = context3D.createIndexBuffer(meshIndexData.length);
			indexBuffer.uploadFromVector(meshIndexData, 0, meshIndexData.length);
			
//			上传网格顶点数据
//			因为包含X, Y, Z, U, V, nX, nY, nZ, 所以每个顶点各占8个数组元素
			vertexBuffer = context3D.createVertexBuffer(meshVertexData.length/8, 8);
			vertexBuffer.uploadFromVector(meshVertexData, 0 , meshVertexData.length/8);
			
//			产生MIP映射
			myTexture = context3D.createTexture(textureSize, textureSize, Context3DTextureFormat.BGRA, false);
			var ws:int = myTextureData.bitmapData.width;
			var hs:int = myTextureData.bitmapData.height;
			var level:int = 0;
			var temp:BitmapData;
			var transform:Matrix = new Matrix();
			temp = new BitmapData(ws, hs, true, 0x000000);
			while(ws>=1 && hs>=1)
			{
				temp.draw(myTextureData.bitmapData, transform, null, null, null, true);
				myTexture.uploadFromBitmapData(temp, level);
				transform.scale(0.5, 0.5);
				level++;
				ws >>=1;
				hs >>=1;
				if(hs && ws)
				{
					temp.dispose();
					temp = new BitmapData(ws, hs, true, 0x000000);
				}
			}
			temp.dispose();
			
//			为场景创建透视矩阵
			projectionMatrix.identity();
//			45视域， 640/480长宽比， 0.1=近裁剪面， 100=远裁剪面
			projectionMatrix.perspectiveFieldOfViewRH(45, swfWidth/swfHeight, 0.01, 100);
			
//			创建一个定义相机位置的矩阵
			viewMatrix.identity();
//			为了看到网格， 把相机后退一点
			viewMatrix.appendTranslation(0,0,-4);
			
			addEventListener(Event.ENTER_FRAME, enterFrameHandle);
			
		}
		
		private var t:Number = 0.0;
		private function enterFrameHandle(e:Event):void
		{
//			渲染前，先清除旧的一帧
			context3D.clear(0,0,0);
			
			context3D.setProgram(shaderProgram);
//			创建变换矩阵
			modelMatrix.identity();
			modelMatrix.appendRotation(t*0.7, Vector3D.Y_AXIS);
			modelMatrix.appendRotation(t*0.6, Vector3D.X_AXIS);
			modelMatrix.appendRotation(t*1, Vector3D.Y_AXIS);
			modelMatrix.appendTranslation(0,0,0);
			modelMatrix.appendRotation(90, Vector3D.X_AXIS);
			
			t += 2.0;
			
//			重置矩阵，然后添加新的角度
			modelViewProjection.identity();
			modelViewProjection.append(modelMatrix);
			modelViewProjection.append(viewMatrix);
			modelViewProjection.append(projectionMatrix);
			
//			把矩阵传入着色器
			context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, modelViewProjection, true);
			
//			用当前着色器处理顶点数据
//			顶点位置
			context3D.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
//			纹理坐标
			context3D.setVertexBufferAt(1, vertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_3);
			
//			使用哪个纹理
			context3D.setTextureAt(0, myTexture);
			
//			绘制三角面
			context3D.drawTriangles(indexBuffer, 0, meshIndexData.length/3);
//			呈现/交换后备缓冲区
			context3D.present();
			
		}
		
		private function initData():void
		{
//			为多边形定义它们各自使用的顶点
			meshIndexData = Vector.<uint>
				([
				0,1,2,0,2,3
				]);
			
			meshVertexData = Vector.<Number>
				([
//				x, y, z,	u, v,	nx, ny, nz
				-1,-1,1,	0,0,	0, 0, 1,
				1,-1,1,		1,0,	0,0,1,
				1,1,1,		1,1,	0,0,1,
				-1,1,1,		0,1,	0,0,1
				]);
			
		}
		
		
		
	}
}