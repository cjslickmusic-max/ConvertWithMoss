// Written for Razumov Ultimate Sampler (LGPL ConvertWithMoss fork patch).
// Licensed under LGPLv3 - http://www.gnu.org/licenses/lgpl-3.0.txt

package de.mossgrabers.convertwithmoss.core;

/**
 * Emits machine-readable conversion progress on stderr for hosts (RUS Kontakt import).
 * Format: {@code RUS_CWM_PROGRESS pct=<0..100> phase=<token> detail=<text>}
 */
public final class MachineProgressReporter
{
    private static boolean cliRequested = false;


    private MachineProgressReporter ()
    {
        // Utility
    }


    public static void setCliRequested (final boolean requested)
    {
        cliRequested = requested;
    }


    public static boolean isEnabled ()
    {
        if (cliRequested)
            return true;

        final String env = System.getenv ("RUS_CWM_MACHINE_PROGRESS");
        if (env == null)
            return false;

        return env.equalsIgnoreCase ("1") || env.equalsIgnoreCase ("true");
    }


    public static void report (final int pct, final String phase, final String detail)
    {
        if (!isEnabled ())
            return;

        final int p = Math.max (0, Math.min (100, pct));
        final String ph = sanitizeToken (phase, "convert");
        final String det = sanitizeDetail (detail);
        System.err.println ("RUS_CWM_PROGRESS pct=" + p + " phase=" + ph + " detail=" + det);
        System.err.flush ();
    }


    private static String sanitizeToken (final String s, final String fallback)
    {
        if (s == null || s.isBlank ())
            return fallback;

        final StringBuilder sb = new StringBuilder ();
        for (int i = 0; i < s.length (); ++i)
        {
            final char c = s.charAt (i);
            if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')
                || c == '.' || c == '_' || c == '-')
                sb.append (c);
        }
        return sb.length () > 0 ? sb.toString () : fallback;
    }


    private static String sanitizeDetail (final String detail)
    {
        if (detail == null)
            return "";

        String d = detail.replace ('\r', ' ').replace ('\n', ' ').trim ();
        if (d.length () > 180)
            d = d.substring (d.length () - 180);
        return d;
    }
}
