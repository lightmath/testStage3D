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
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.getTimer;
	
	/**
	 * 
	 * @author licheng
	 * 2014-9-15下午3:53:57
	 */	
	[SWF(width="640", height="480", frameRate="60", backgroundCorlor="0xCCFF00")]
	public class Stage3dGame02 extends Sprite
	{
		//FPS显示相关
		private var fpsLast:uint = getTimer();
		private var fpsTicks:uint = 0;
		private var fpsTf:TextField;
		
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
		private var shaderProgram1:Program3D;
		private var shaderProgram2:Program3D;
		private var shaderProgram3:Program3D;
		private var shaderProgram4:Program3D;
		/**
		 * 网格用到的顶点
		 */		
		private var vertexBuffer:VertexBuffer3D;
		/**
		 * 网格的顶点索引
		 */		
		private var indexBuffer:IndexBuffer3D;
		/**
		 * 用于定义3D网格模型的数据
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
		
		private var t:Number = 0.0;
		private var looptemp:int = 0;
		
		[Embed (source="texture.jpg")]
		private var myTextureBitmap:Class;
		private var myTextureData:Bitmap = new myTextureBitmap();
		private var myTexture:Texture;
		
		public function Stage3dGame02()
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
			initGUI();
			stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, onContext3DCreate);
			stage.stage3Ds[0].requestContext3D();
			
		}
		
		private function initGUI():void
		{
			var myFormat:TextFormat = new TextFormat();
			myFormat.color = 0xFFFFFF;
			myFormat.size = 13;
			
//			显示帧频的FPS计数器
			fpsTf = new TextField();
			fpsTf.x = 0;
			fpsTf.y = 0;
			fpsTf.selectable = false;
			fpsTf.autoSize = TextFieldAutoSize.LEFT;
			fpsTf.defaultTextFormat = myFormat;
			fpsTf.text = "Initializing Stage3D...";
			addChild(fpsTf);
			
			var label1:TextField = new TextField();
			label1.x = 100;
			label1.y = 180;
			label1.selectable = false;
			label1.autoSize = TextFieldAutoSize.LEFT;
			label1.defaultTextFormat = myFormat;
			label1.text = "Shader 1:Textured";
			addChild(label1);
			
			var label2:TextField = new TextField();
			label2.x = 400;
			label2.y = 180;
			label2.selectable = false;
			label2.autoSize = TextFieldAutoSize.LEFT;
			label2.defaultTextFormat = myFormat;
			label2.text = "Shader 2: Vertex RGB";
			addChild(label2);
			
			var label3:TextField = new TextField();
			label3.x = 80;
			label3.y = 440;
			label3.selectable = false;
			label3.autoSize = TextFieldAutoSize.LEFT;
			label3.defaultTextFormat = myFormat;
			label3.text = "Shader 3: Vertex RGB + Textrued";
			addChild(label3);
			
			var label4:TextField = new TextField();
			label4.x = 340;
			label4.y = 440;
			label4.selectable = false;
			label4.autoSize = TextFieldAutoSize.LEFT;
			label4.defaultTextFormat = myFormat;
			label4.text = "Shader 4: Textured + setProgramConstants";
			addChild(label4);
			
			
			
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
			
			initShaders();
			
//			上传网格索引
			indexBuffer = context3D.createIndexBuffer(meshIndexData.length);
			indexBuffer.uploadFromVector(meshIndexData, 0, meshIndexData.length);
			
//			上传网格顶点数据
//			因为包含X, Y, Z, U, V, nX, nY, nZ,r,g,b,a,  所以每个顶点各占8个数组元素
			vertexBuffer = context3D.createVertexBuffer(meshVertexData.length/12, 12);
			vertexBuffer.uploadFromVector(meshVertexData, 0 , meshVertexData.length/12);
			
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
			viewMatrix.appendTranslation(0,0,-10);
			
			addEventListener(Event.ENTER_FRAME, enterFrameHandle);
			
		}
		
		private function enterFrameHandle(e:Event):void
		{
			//			渲染前，先清除旧的一帧
			context3D.clear(0,0,0);

			t += 2.0;
//			遍历我们想要绘制的每个网格
			for(looptemp = 0; looptemp<4;looptemp++)
			{
//				把变换矩阵清零
				modelMatrix.identity();
//				每个网格各使用一种纹理、着色器、位置和旋转速度
				switch(looptemp)
				{
					case 0:
						context3D.setTextureAt(0, myTexture);
						context3D.setProgram(shaderProgram1);
						modelMatrix.appendRotation(t*0.7, Vector3D.Y_AXIS);
						modelMatrix.appendRotation(t*0.6, Vector3D.X_AXIS);
						modelMatrix.appendRotation(t*1, Vector3D.Y_AXIS);
						modelMatrix.appendTranslation(-3,3,0);
						break;
					
					case 1:
						context3D.setTextureAt(0, null);
						context3D.setProgram(shaderProgram2);
						modelMatrix.appendRotation(t*-0.2, Vector3D.Y_AXIS);
						modelMatrix.appendRotation(t*0.4, Vector3D.X_AXIS);
						modelMatrix.appendRotation(t*0.7, Vector3D.Y_AXIS);
						modelMatrix.appendTranslation(3,3,0);
						break;
					
					case 2:
						context3D.setTextureAt(0, myTexture);
						context3D.setProgram(shaderProgram3);
						modelMatrix.appendRotation(t*1.0, Vector3D.Y_AXIS);
						modelMatrix.appendRotation(t*-0.2, Vector3D.X_AXIS);
						modelMatrix.appendRotation(t*0.3, Vector3D.Y_AXIS);
						modelMatrix.appendTranslation(-3,-3,0);
						break;
					
					case 3:
						context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, 
									Vector.<Number>([1, Math.abs(Math.cos(t/50)), 0, 1]));
						context3D.setTextureAt(0, myTexture);
						context3D.setProgram(shaderProgram4);
						modelMatrix.appendRotation(t*0.3, Vector3D.Y_AXIS);
						modelMatrix.appendRotation(t*0.3, Vector3D.X_AXIS);
						modelMatrix.appendRotation(t*-0.3, Vector3D.Y_AXIS);
						modelMatrix.appendTranslation(3,-3,0);
						break;
				}
				
			}
			
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
			context3D.setVertexBufferAt(1, vertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_2);
			
			context3D.setVertexBufferAt(2, vertexBuffer, 8, Context3DVertexBufferFormat.FLOAT_4);
			
			//			绘制三角面
			context3D.drawTriangles(indexBuffer, 0, meshIndexData.length/3);
			//			呈现/交换后备缓冲区
			context3D.present();
			
			
			fpsTicks++;
			var now:uint = getTimer();
			var delta:uint = now-fpsLast;
			if(delta >= 1000)
			{
				var fps:Number = fpsTicks/delta*1000;
				fpsTf.text = fps.toFixed(1)+"fps";
				fpsTicks = 0;
				fpsLast = now;
			}
			
			
		}
		
		private function initShaders():void
		{
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
					"mov v1, va1\n"+
//				告诉片段着色器r,g,b,a的值	
					"mov v2, va2\n"
				);
			
//			一个简单的片段着色器，使用顶点位置和纹理颜色
			var fragmentShaderAssembler1:AGALMiniAssembler = new AGALMiniAssembler();
			fragmentShaderAssembler1.assemble
				(
					Context3DProgramType.FRAGMENT,
//				使用存于v1中的u，v坐标， 从纹理fs0中取得纹理的颜色
					"tex ft0, v1, fs0 <2d, repeat,miplinear>\n"+
//				将结果输出
					"mov oc, ft0\n"
				);
			
//			没有纹理， 使用顶点缓冲数据中的r,g,b,a值
			var fragmentShaderAssembler2:AGALMiniAssembler = new AGALMiniAssembler();
			fragmentShaderAssembler2.assemble(Context3DProgramType.FRAGMENT, 
//				从v2寄存器中获取颜色， 这个值是被顶点着色器插入的
				"mov oc, v2\n"
			);
			
//			使用u,v坐标进行纹理采样， 同时也使用顶点颜色进行上色
			var fragmentShaderAssembler3:AGALMiniAssembler = new AGALMiniAssembler();
			fragmentShaderAssembler3.assemble(Context3DProgramType.FRAGMENT, 
//				从纹理采样寄存器0中获取纹理颜色
//				从变量寄存器1中获取u，v坐标
				"tex ft0, v1, fs0 <2d, repeat,miplinear>\n"+
//				乘以存储在v2中的值(顶点颜色)
				"mul ft1,v2, ft0\n"+
//				将结果移给输出颜色寄存器
				"mov oc, ft1\n"
			);
			
//			使用u,v坐标进行纹理采样， 并使用一个常量进行染色
			var fragmentShaderAssembler4:AGALMiniAssembler = new AGALMiniAssembler();
			fragmentShaderAssembler4.assemble(Context3DProgramType.FRAGMENT, 
//				从纹理采样寄存器0中获取纹理颜色
//				从变量寄存器1中获取u，v坐标
				"tex ft0, v1, fs0 <2d, repeat,miplinear>\n"+
//				乘以存储在fc0中的值(顶点颜色)
				"mul ft1,fc0, ft0\n"+
//				将结果移给输出颜色寄存器
				"mov oc, ft1\n"
			);
			
			
//			将两者混合成着色器， 随后上传给GPU
			shaderProgram1 = context3D.createProgram();
			shaderProgram1.upload(vertexShaderAssembler.agalcode,
				fragmentShaderAssembler1.agalcode);
			
			shaderProgram2 = context3D.createProgram();
			shaderProgram2.upload(vertexShaderAssembler.agalcode,
				fragmentShaderAssembler2.agalcode);
			
			shaderProgram3 = context3D.createProgram();
			shaderProgram3.upload(vertexShaderAssembler.agalcode,
				fragmentShaderAssembler3.agalcode);
			
			shaderProgram4 = context3D.createProgram();
			shaderProgram4.upload(vertexShaderAssembler.agalcode,
				fragmentShaderAssembler4.agalcode);
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
//					x, y, z,	u, v,	nx, ny, nz
					-1,-1,1,	0,0,	0, 0, 1,		1.0, 0.0, 0.0, 1.0,
					1,-1,1,		1,0,	0, 0, 1,		0.0, 1.0, 0.0, 1.0,
					1,1,1,		1,1,	0, 0, 1,		0.0, 0.0, 1.0, 1.0,
					-1,1,1,		0,1,	0, 0, 1,		1.0, 1.0, 1.0, 1.0
				]);
			
		}
		
	}
}