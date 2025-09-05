import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Complications;

class CleanWatchFaceView extends WatchUi.WatchFace {

    var hrProvider;
    var hrId;
    var hrComp;
    var currentHr = null;

    function initialize() {
        WatchFace.initialize();
        
        // Créer un provider de complication pour le rythme cardiaque
        if (Toybox has :Complications) {
            hrId = new Id(Complications.COMPLICATION_TYPE_HEART_RATE);
            if (hrId != null) {
                hrComp = Complications.getComplication(hrId);
                Complications.registerComplicationChangeCallback(self.method(:onComplicationChanged));
                Complications.subscribeToUpdates(hrId);        
            }
        }

    }

    function onComplicationChanged(id as Complications.Id) as Void {
        if (id.equals(hrId)) {
            currentHr = Complications.getComplication(id).value;
        }

    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Get and show the current time
        var clockTime = System.getClockTime();
        
        // Format and display hours
        var hourString = Lang.format("$1$", [clockTime.hour.format("%02d")]);
        var hourView = View.findDrawableById("HourLabel") as Text;
        hourView.setText(hourString);
        
        // Format and display minutes
        var minuteString = Lang.format("$1$", [clockTime.min.format("%02d")]);
        var minuteView = View.findDrawableById("MinuteLabel") as Text;
        minuteView.setText(minuteString);
        
        // Get and display heart rate
        var heartRateString = getHeartRateString();
        var heartRateView = View.findDrawableById("HeartRateLabel") as Text;
        heartRateView.setText(heartRateString);

        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
        
        // Draw minute markers
        drawMinuteMarkers(dc);
        
        // Draw debug center cross
        // drawCenterCross(dc);
        
        // Draw heart symbol
        drawHeartSymbol(dc);
        
        // Draw the seconds arc
        drawSecondsArc(dc, clockTime.sec);
    }
    
    // Get heart rate as a formatted string using Garmin complications
    function getHeartRateString() as String {
        var heartRate = null;

        heartRate = currentHr;
        
        if (heartRate != null && heartRate > 0) {
            return Lang.format("$1$", [heartRate.format("%d")]);
        } else {
            return "--";
        }
    }
    
    // Draw a heart symbol under the time
    function drawHeartSymbol(dc as Dc) as Void {
        var width = dc.getWidth();
        var centerX = width / 2;
        var heartY = 310; // Position between time and heart rate text

        // Draw manual heart (left side)
        var size = 8;
        
        // Set heart color
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        
        // Draw a simple heart shape using circles and a triangle
        // Left circle
        dc.fillCircle(centerX - size/2, heartY - size/4, size/2);
        // Right circle  
        dc.fillCircle(centerX + size/2, heartY - size/4, size/2);
        // Bottom triangle (heart point)
        dc.fillPolygon([
            [centerX - size, heartY],
            [centerX + size, heartY], 
            [centerX, heartY + size]
        ]);
    }
    
    // Draw minute markers around the watch face
    function drawMinuteMarkers(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;
        var margin = 0;
        var outerRadius = (width < height ? width : height) / 2 - margin; // Outer edge with small margin
        var innerRadius = outerRadius - 5; // Inner edge for minute markers
        var hourInnerRadius = outerRadius - 12; // Longer markers for hours
        
        // Set marker properties
        // dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        // dc.setPenWidth(1);
        
        // Dessiner 120 traits, un toutes les 0,5 secondes (360°/120 = 3° par trait)
        for (var i = 0; i < 120; i++) {
            var angle = (i * 3) - 90; // 3 degrés par trait, commence à midi
            var angleRad = Math.toRadians(angle);

            // Marqueur d'heure toutes les 10 traits (soit toutes les 5 secondes)
            var isHourMarker = (i % 10) == 0;
            var startRadius = isHourMarker ? hourInnerRadius : innerRadius;
            if (isHourMarker) {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(2);
                startRadius = hourInnerRadius;
            } else if ((i % 2) == 0) {
                dc.setColor(0xc7c7c7, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(1);
                startRadius = innerRadius;
            } else {
                dc.setColor(0x4d4d4d, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(1);
                startRadius = outerRadius - 2;
            }

            // Calculer les points de départ et d'arrivée
            var startX = centerX + startRadius * Math.cos(angleRad);
            var startY = centerY + startRadius * Math.sin(angleRad);
            var endX = centerX + outerRadius * Math.cos(angleRad);
            var endY = centerY + outerRadius * Math.sin(angleRad);

            // Dessiner le trait
            dc.drawLine(startX, startY, endX, endY);
        }
    }
    
    // Draw a debug cross at the center of the screen
    function drawCenterCross(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;
        var crossSize = 12; // Length of each arm of the cross
        
        // Set cross properties
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        
        // Draw horizontal line
        dc.drawLine(centerX - crossSize, centerY, centerX + crossSize, centerY);
        
        // Draw vertical line
        dc.drawLine(centerX, centerY - crossSize, centerX, centerY + crossSize);
        
        // Optional: Draw a small circle at the exact center
        // dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        // dc.fillCircle(centerX, centerY, 5);
    }
    
    // Draw an arc that progresses with seconds
    function drawSecondsArc(dc as Dc, seconds as Number) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;
        var margin = 0;
        var radius = (width < height ? width : height) / 2 - margin; // 20px margin from edge
        
        // Calculate the angle based on seconds (0-59 seconds = 0-360 degrees)
        // Start from top (12 o'clock position), so subtract 90 degrees
        var startAngle = 90; // Start at top
        var sweepAngle = 360 - (seconds * 360) / 60; // Convert seconds to degrees
        
        // Set arc properties
        // dc.setColor(0x35876d, Graphics.COLOR_TRANSPARENT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(12);
        
        // Draw the arc (only if there are seconds to show)
        if (seconds > 0) {
            dc.drawArc(centerX, centerY, radius, Graphics.ARC_CLOCKWISE, startAngle, startAngle + sweepAngle);
        }
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }

}
