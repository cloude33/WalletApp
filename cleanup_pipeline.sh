#!/bin/bash

echo "🚀 Flutter Proje Temizleme Başlıyor..."

# 1. Cache temizleme
echo "🗑️  Cache temizleniyor..."
flutter clean
rm -rf .dart_tool
rm -rf .flutter-plugins
rm -rf .packages
rm -rf build/
rm -rf ios/Pods

# 2. Package güncelleme
echo "📦 Paketler güncelleniyor..."
flutter pub get

# 3. Kullanılmayan import temizleme
echo "🔍 Kullanılmayan import'lar temizleniyor..."
dart fix --apply

# 4. Formatlama
echo "🎨 Kod formatlanıyor..."
flutter format lib/

# 5. Analiz
echo "📊 Kod analizi yapılıyor..."
flutter analyze

# 6. Kullanılmayan dosya kontrolü
echo "📁 Kullanılmayan dosyalar kontrol ediliyor..."
find lib -name "*.dart" -type f | while read file; do
    filename=$(basename "$file" .dart)
    count=$(grep -r "$filename" lib --include="*.dart" | wc -l)
    if [ "$count" -le 2 ]; then
        echo "⚠️  Şüpheli dosya: $file"
    fi
done

# 7. Büyük dosya kontrolü
echo "📏 Büyük dosyalar kontrol ediliyor..."
find lib -name "*.dart" -type f -size +100k -exec ls -lh {} \;

echo "✅ Temizleme tamamlandı!"