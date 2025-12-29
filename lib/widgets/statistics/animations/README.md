# İstatistik Animasyonları

Bu klasör, İstatistik ekranı için kullanılan tüm animasyon widget'larını içerir.

## Animasyon Tipleri

### 1. Fade In Animation
Yumuşak bir şekilde görünme animasyonu.

**Kullanım:**
```dart
FadeInAnimation(
  delay: Duration(milliseconds: 100),
  duration: Duration(milliseconds: 300),
  curve: Curves.easeIn,
  child: YourWidget(),
)
```

**Parametreler:**
- `delay`: Animasyonun başlaması için bekleme süresi
- `duration`: Animasyon süresi (varsayılan: 300ms)
- `curve`: Animasyon eğrisi (varsayılan: Curves.easeIn)

### 2. Slide Transition Animation
Belirli bir yönden kayarak gelen animasyon.

**Kullanım:**
```dart
SlideTransitionAnimation(
  delay: Duration(milliseconds: 100),
  duration: Duration(milliseconds: 250),
  direction: SlideDirection.up,
  offset: 1.0,
  child: YourWidget(),
)
```

**Yönler:**
- `SlideDirection.left`: Soldan sağa
- `SlideDirection.right`: Sağdan sola
- `SlideDirection.up`: Aşağıdan yukarı
- `SlideDirection.down`: Yukarıdan aşağı

**Parametreler:**
- `direction`: Kayma yönü
- `offset`: Kayma mesafesi (varsayılan: 1.0)
- `duration`: Animasyon süresi (varsayılan: 250ms)

### 3. Scale Animation
Büyüyerek görünen animasyon.

**Kullanım:**
```dart
ScaleAnimation(
  delay: Duration(milliseconds: 100),
  duration: Duration(milliseconds: 200),
  beginScale: 0.0,
  endScale: 1.0,
  alignment: Alignment.center,
  child: YourWidget(),
)
```

**Parametreler:**
- `beginScale`: Başlangıç ölçeği (varsayılan: 0.0)
- `endScale`: Bitiş ölçeği (varsayılan: 1.0)
- `alignment`: Ölçekleme merkezi (varsayılan: Alignment.center)
- `duration`: Animasyon süresi (varsayılan: 200ms)

### 4. Chart Animation
Grafiklere özel animasyonlar.

**ChartAnimation:**
Grafiği soldan sağa açan animasyon.

```dart
ChartAnimation(
  delay: Duration(milliseconds: 100),
  duration: Duration(milliseconds: 500),
  child: YourChartWidget(),
)
```

**ChartRevealAnimation:**
Fade ve scale kombinasyonu ile grafik açılma animasyonu.

```dart
ChartRevealAnimation(
  delay: Duration(milliseconds: 100),
  duration: Duration(milliseconds: 500),
  child: YourChartWidget(),
)
```

### 5. Staggered Animation
Kademeli olarak görünen liste animasyonu.

**Kullanım:**
```dart
StaggeredAnimation(
  index: 0,
  staggerDelay: Duration(milliseconds: 50),
  useFade: true,
  useSlide: true,
  useScale: false,
  slideDirection: SlideDirection.up,
  child: YourWidget(),
)
```

**StaggeredListView:**
Liste için hazır staggered animasyon.

```dart
StaggeredListView(
  staggerDelay: Duration(milliseconds: 50),
  children: [
    Widget1(),
    Widget2(),
    Widget3(),
  ],
)
```

## Hazır Animasyonlu Widget'lar

### AnimatedSummaryCard
Animasyonlu özet kartı.

```dart
AnimatedSummaryCard(
  title: 'Toplam Gelir',
  value: '₺25,000',
  subtitle: 'Bu ay',
  icon: Icons.trending_up,
  color: Colors.green,
  delay: Duration(milliseconds: 100),
  enableAnimation: true,
)
```

### AnimatedMetricCard
Animasyonlu metrik kartı.

```dart
AnimatedMetricCard(
  label: 'Net Akış',
  value: '₺6,500',
  change: '+15%',
  trend: TrendDirection.up,
  color: Colors.green,
  delay: Duration(milliseconds: 100),
  enableAnimation: true,
)
```

### AnimatedChartCard
Animasyonlu grafik kartı.

```dart
AnimatedChartCard(
  title: 'Nakit Akışı Trendi',
  subtitle: 'Son 6 ay',
  delay: Duration(milliseconds: 100),
  enableAnimation: true,
  chart: InteractiveLineChart(...),
)
```

## Animasyon Süreleri

Tutarlılık için önerilen süreler:

- **Fade In**: 300ms
- **Slide**: 250ms
- **Scale**: 200ms
- **Chart**: 500ms
- **Stagger Delay**: 50ms/öğe

## Animasyon Eğrileri

Önerilen eğriler:

- **Fade In**: `Curves.easeIn`
- **Slide**: `Curves.easeOut`
- **Scale**: `Curves.easeOut`
- **Chart**: `Curves.easeInOut`

## Performans İpuçları

1. **Animasyonları Devre Dışı Bırakma:**
   ```dart
   AnimatedSummaryCard(
     enableAnimation: false,
     // ...
   )
   ```

2. **Stagger Delay'i Ayarlama:**
   Çok fazla öğe varsa, delay'i azaltın:
   ```dart
   StaggeredAnimation(
     staggerDelay: Duration(milliseconds: 30),
     // ...
   )
   ```

3. **Animasyon Kontrolü:**
   Kullanıcı tercihlerine göre animasyonları kontrol edin:
   ```dart
   final enableAnimations = settings.enableAnimations;
   
   AnimatedSummaryCard(
     enableAnimation: enableAnimations,
     // ...
   )
   ```

## Örnek Kullanım

Tam örnek için `animations_example.dart` dosyasına bakın.

```dart
import 'package:money/widgets/statistics/animations/animations.dart';

class MyStatisticsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        AnimatedSummaryCard(
          title: 'Toplam Gelir',
          value: '₺25,000',
          icon: Icons.trending_up,
          color: Colors.green,
          delay: Duration(milliseconds: 100),
        ),
        AnimatedSummaryCard(
          title: 'Toplam Gider',
          value: '₺18,500',
          icon: Icons.trending_down,
          color: Colors.red,
          delay: Duration(milliseconds: 200),
        ),
        AnimatedChartCard(
          title: 'Nakit Akışı',
          delay: Duration(milliseconds: 300),
          chart: InteractiveLineChart(...),
        ),
      ],
    );
  }
}
```

## Gereksinimler

- Flutter 3.10.0+
- Dart 3.10.0+

## Notlar

- Tüm animasyonlar `SingleTickerProviderStateMixin` kullanır
- Animasyonlar otomatik olarak dispose edilir
- Delay parametresi ile animasyonlar sıralanabilir
- Chart animasyonları fl_chart paketinin built-in animasyonlarını kullanır
