import 'dart:io';
import 'dart:ui' as ui;

/// Simple app icon generator for Flutter projects
/// This creates basic app icons from a simple design
Future<void> generateAppIcons() async {
  print('Generating app icons...');
  
  // Create assets directory if it doesn't exist
  final assetsDir = Directory('assets/app_icons');
  if (!await assetsDir.exists()) {
    await assetsDir.create(recursive: true);
  }
  
  // Generate iOS icons
  await _generateIOSIcons();
  
  // Generate Android icons  
  await _generateAndroidIcons();
  
  print('App icons generated successfully!');
}

Future<void> _generateIOSIcons() async {
  final sizes = {
    '20': ['1x', '2x', '3x'],
    '29': ['1x', '2x', '3x'], 
    '40': ['1x', '2x', '3x'],
    '60': ['2x', '3x'],
    '76': ['1x', '2x'],
    '83.5': ['2x'],
    '1024': ['1x']
  };
  
  for (final size in sizes.entries) {
    for (final scale in size.value) {
      final actualSize = size.key == '1024' 
          ? 1024 
          : int.parse(size.key) * (scale == '1x' ? 1 : scale == '2x' ? 2 : 3);
      
      final fileName = size.key == '1024' 
          ? 'Icon-App-1024x1024@1x.png'
          : 'Icon-App-${size.key}x${size.key}@${scale}.png';
      
      await _generateIcon(actualSize, 'ios/Runner/Assets.xcassets/AppIcon.appiconset/$fileName');
    }
  }
}

Future<void> _generateAndroidIcons() async {
  final sizes = {
    'hdpi': 72,
    'mdpi': 48, 
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192
  };
  
  for (final size in sizes.entries) {
    await _generateIcon(size.value, 'android/app/src/main/res/mipmap-${size.key}/ic_launcher.png');
  }
}

Future<void> _generateIcon(int size, String outputPath) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  
  // Create a simple paw print icon
  final paint = ui.Paint()
    ..color = const ui.Color(0xFFFE9A00)
    ..style = ui.PaintingStyle.fill;
    
  final whitePaint = ui.Paint()
    ..color = const ui.Color(0xFFFFFFFF)
    ..style = ui.PaintingStyle.fill;
  
  // Background
  canvas.drawRect(ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()), paint);
  
  // Paw print (simplified)
  final centerX = size / 2;
  final centerY = size / 2;
  final scale = size / 1024;
  
  // Main pad
  canvas.drawOval(
    ui.Rect.fromCenter(
      center: ui.Offset(centerX, centerY + 50 * scale),
      width: 240 * scale,
      height: 200 * scale,
    ),
    whitePaint,
  );
  
  // Toe pads
  final toePositions = [
    ui.Offset(centerX - 80 * scale, centerY - 50 * scale),
    ui.Offset(centerX + 80 * scale, centerY - 50 * scale),
    ui.Offset(centerX - 40 * scale, centerY - 120 * scale),
    ui.Offset(centerX + 40 * scale, centerY - 120 * scale),
  ];
  
  for (final position in toePositions) {
    canvas.drawOval(
      ui.Rect.fromCenter(
        center: position,
        width: 70 * scale,
        height: 90 * scale,
      ),
      whitePaint,
    );
  }
  
  final picture = recorder.endRecording();
  final img = await picture.toImage(size, size);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  
  final file = File(outputPath);
  await file.create(recursive: true);
  await file.writeAsBytes(data!.buffer.asUint8List());
  
  print('Generated icon: $outputPath (${size}x${size})');
}

void main() async {
  await generateAppIcons();
}
