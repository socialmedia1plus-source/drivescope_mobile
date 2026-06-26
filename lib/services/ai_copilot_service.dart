import '../models/trip_model.dart';

class AICopilotService {
  Map<String, dynamic> analyzeDriverPerformance(List<TripModel> trips) {
    if (trips.isEmpty) {
      return {
        'status': 'empty',
        'efficiencyScore': 0,
        'earningsPerKm': 0.0,
        'bestPlatform': 'غير محدد',
        'recommendation': 'أهلاً بك في DriveScope كابتن! ابدأ بتسجيل رحلاتك الأولى اليوم، وسيقوم الـ AI بتحليل معدل استهلاك الوقود وصافي أرباحك لكل كيلومتر ليوجهك إلى المنصة الأكثر ربحية في منطقتك.'
      };
    }

    double totalEarnings = 0.0;
    double totalKm = 0.0;
    Map<String, double> platformEarnings = {};
    Map<String, double> platformKm = {};

    for (var trip in trips) {
      totalEarnings += trip.netEarnings;
      totalKm += trip.distanceKm;

      platformEarnings[trip.platform] = (platformEarnings[trip.platform] ?? 0.0) + trip.netEarnings;
      platformKm[trip.platform] = (platformKm[trip.platform] ?? 0.0) + trip.distanceKm;
    }

    double earningsPerKm = totalKm > 0 ? totalEarnings / totalKm : 0.0;

    // حساب درجة كفاءة الأرباح (مثال: اعتبار 15 ج.م لكل كم كفاءة 100%)
    double targetEarningsPerKm = 15.0;
    int efficiencyScore = ((earningsPerKm / targetEarningsPerKm) * 100).round();
    if (efficiencyScore > 100) efficiencyScore = 100;
    if (efficiencyScore < 0) efficiencyScore = 0;

    // تحديد المنصة الأعلى إنتاجية لكابتن
    String bestPlatform = 'Uber';
    double maxRate = 0.0;

    platformEarnings.forEach((platform, earnings) {
      double km = platformKm[platform] ?? 1.0;
      double rate = earnings / km;
      if (rate > maxRate) {
        maxRate = rate;
        bestPlatform = platform;
      }
    });

    // صياغة التوصية الذكية بناءً على الأرقام الحقيقية للرحلات
    String recommendation = '';
    if (efficiencyScore >= 80) {
      recommendation = 'عاش يا كابتن! أدائك ممتاز جداً ومعدل دخلك الصافي لكل كيلومتر مثالي. استمر في التركيز على منصة $bestPlatform لأنها تحقق لك أعلى عائد حالياً.';
    } else if (efficiencyScore >= 50) {
      recommendation = 'أدائك متوسط يا كابتن. نلاحظ أن منصة $bestPlatform تمنحك عوائد أفضل مقارنة بالمسافات المقطوعة، ننصحك بتقليل قبول الرحلات طويلة المسافة ذات الأجرة المنخفضة لرفع كفاءة محفظتك.';
    } else {
      recommendation = 'تنبيه ذكي: معدل الأرباح الحالي منخفض مقارنة بالمسافات المقطوعة واستهلاك السيارة. يُفضل التركيز على أوقات الذروة (Peak Hours) والاعتماد أكثر على منصة $bestPlatform لتحسين صافي الدخل الحقيقي.';
    }

    return {
      'status': 'success',
      'efficiencyScore': efficiencyScore,
      'earningsPerKm': earningsPerKm,
      'bestPlatform': bestPlatform,
      'recommendation': recommendation
    };
  }
}