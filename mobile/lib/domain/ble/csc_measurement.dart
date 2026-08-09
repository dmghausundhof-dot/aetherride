/// BLE CSC Measurement (0x2A5B) helpers — kept testable without FlutterBlue.
class CscMeasurement {
  const CscMeasurement({
    required this.speedKmh,
    required this.cadenceRpm,
    this.prevWheelRevs,
    this.prevWheelEventTime,
    this.prevCrankRevs,
    this.prevCrankEventTime,
  });

  final double speedKmh;
  final double cadenceRpm;
  final int? prevWheelRevs;
  final int? prevWheelEventTime;
  final int? prevCrankRevs;
  final int? prevCrankEventTime;
}

/// Parse CSC Measurement bytes. Speed only from wheel; cadence only from crank.
CscMeasurement parseCscMeasurement(
  List<int> data, {
  required double wheelCircumferenceM,
  int? prevWheelRevs,
  int? prevWheelEventTime,
  int? prevCrankRevs,
  int? prevCrankEventTime,
  double speedKmh = 0,
  double cadenceRpm = 0,
}) {
  if (data.isEmpty) {
    return CscMeasurement(
      speedKmh: speedKmh,
      cadenceRpm: cadenceRpm,
      prevWheelRevs: prevWheelRevs,
      prevWheelEventTime: prevWheelEventTime,
      prevCrankRevs: prevCrankRevs,
      prevCrankEventTime: prevCrankEventTime,
    );
  }

  final flags = data[0];
  var i = 1;
  final hasWheel = (flags & 0x01) != 0;
  final hasCrank = (flags & 0x02) != 0;
  var nextWheelRevs = prevWheelRevs;
  var nextWheelTime = prevWheelEventTime;
  var nextCrankRevs = prevCrankRevs;
  var nextCrankTime = prevCrankEventTime;
  var speed = speedKmh;
  var cadence = cadenceRpm;

  if (hasWheel) {
    if (data.length < i + 6) {
      return CscMeasurement(
        speedKmh: speed,
        cadenceRpm: cadence,
        prevWheelRevs: nextWheelRevs,
        prevWheelEventTime: nextWheelTime,
        prevCrankRevs: nextCrankRevs,
        prevCrankEventTime: nextCrankTime,
      );
    }
    final revs = data[i] |
        (data[i + 1] << 8) |
        (data[i + 2] << 16) |
        (data[i + 3] << 24);
    final eventTime = data[i + 4] | (data[i + 5] << 8);
    i += 6;
    if (prevWheelRevs != null && prevWheelEventTime != null) {
      var dRevs = revs - prevWheelRevs;
      var dTime = eventTime - prevWheelEventTime;
      if (dRevs < 0) dRevs += 0x100000000;
      if (dTime < 0) dTime += 0x10000;
      if (dTime > 0 && dRevs >= 0) {
        final seconds = dTime / 1024.0;
        final meters = dRevs * wheelCircumferenceM;
        speed = (meters / seconds) * 3.6;
      }
    }
    nextWheelRevs = revs;
    nextWheelTime = eventTime;
  }

  if (hasCrank) {
    if (data.length >= i + 4) {
      final revs = data[i] | (data[i + 1] << 8);
      final eventTime = data[i + 2] | (data[i + 3] << 8);
      if (prevCrankRevs != null && prevCrankEventTime != null) {
        var dRevs = revs - prevCrankRevs;
        var dTime = eventTime - prevCrankEventTime;
        if (dRevs < 0) dRevs += 0x10000;
        if (dTime < 0) dTime += 0x10000;
        if (dTime > 0 && dRevs >= 0) {
          cadence = (dRevs * 60.0) / (dTime / 1024.0);
        }
      }
      nextCrankRevs = revs;
      nextCrankTime = eventTime;
    }
  }

  return CscMeasurement(
    speedKmh: speed,
    cadenceRpm: cadence,
    prevWheelRevs: nextWheelRevs,
    prevWheelEventTime: nextWheelTime,
    prevCrankRevs: nextCrankRevs,
    prevCrankEventTime: nextCrankTime,
  );
}
