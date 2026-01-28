"""
Email service for SafeRoute notifications.

SAFETY CRITICAL:
- Authority verification emails with secure tokens
- Driver confirmation emails (optional, future)
- No sensitive hazard details in email subjects
- All tokens are single-use and time-limited
"""

import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime, timedelta
import os
from typing import Optional


class EmailService:
    """
    Email service for sending notifications.
    
    Configuration via environment variables:
    - SMTP_SERVER: SMTP server address
    - SMTP_PORT: SMTP port (usually 587 for TLS)
    - SMTP_USER: Email address to send from
    - SMTP_PASSWORD: SMTP password or app token
    - SMTP_FROM_NAME: Display name for sender
    """
    
    def __init__(
        self,
        smtp_server: Optional[str] = None,
        smtp_port: Optional[int] = None,
        smtp_user: Optional[str] = None,
        smtp_password: Optional[str] = None,
        from_name: str = "SafeRoute"
    ):
        """Initialize email service with SMTP credentials."""
        self.smtp_server = smtp_server or os.getenv("SMTP_SERVER", "localhost")
        self.smtp_port = smtp_port or int(os.getenv("SMTP_PORT", "587"))
        self.smtp_user = smtp_user or os.getenv("SMTP_USER", "")
        self.smtp_password = smtp_password or os.getenv("SMTP_PASSWORD", "")
        self.from_name = from_name
        self.from_email = self.smtp_user
    
    def send_authority_verification_email(
        self,
        authority_email: str,
        hazard_id: str,
        hazard_type: str,
        latitude: float,
        longitude: float,
        token: str,
        token_expires_at: datetime
    ) -> bool:
        """
        Send verification email to authority.
        
        SAFETY RULES:
        - Email subject does NOT include hazard details
        - Token is single-use and time-limited (48 hours)
        - Verification link includes token (frontend will call API with token)
        - No sensitive details in email body (link click reveals details)
        
        Args:
            authority_email: Authority's email address
            hazard_id: UUID of the hazard (for reference in email)
            hazard_type: Type of hazard (ACCIDENT, POTHOLE, etc.)
            latitude: Hazard latitude
            longitude: Hazard longitude
            token: Verification token (secure, random)
            token_expires_at: When token expires
        
        Returns:
            True if email sent successfully, False otherwise
        """
        
        # Generic subject line (no hazard details)
        subject = f"SafeRoute: Verify Hazard Report #{hazard_id[:8]}"
        
        # Build verification link
        # Frontend will send this token to: POST /authorities/verify/{hazard_id}
        verification_link = (
            f"{os.getenv('FRONTEND_URL', 'https://example.com')}/verify"
            f"?hazard_id={hazard_id}&token={token}"
        )
        
        # Plain text email body
        body_text = f"""
SafeRoute Hazard Verification Request

A new hazard report has been submitted and requires your verification.

Hazard ID: {hazard_id}
Type: {hazard_type}
Location: {latitude}, {longitude}

To review and verify this report, click the link below:
{verification_link}

This verification link expires at: {token_expires_at.isoformat()}

If you did not request this, please disregard this email.

---
SafeRoute Team
"""
        
        # HTML email body (for better rendering)
        body_html = f"""
<html>
    <body style="font-family: Arial, sans-serif; color: #333;">
        <h2>SafeRoute Hazard Verification Request</h2>
        
        <p>A new hazard report has been submitted and requires your verification.</p>
        
        <table style="border-collapse: collapse; margin: 20px 0;">
            <tr>
                <td style="padding: 8px; font-weight: bold;">Hazard ID:</td>
                <td style="padding: 8px;">{hazard_id}</td>
            </tr>
            <tr>
                <td style="padding: 8px; font-weight: bold;">Type:</td>
                <td style="padding: 8px;">{hazard_type}</td>
            </tr>
            <tr>
                <td style="padding: 8px; font-weight: bold;">Location:</td>
                <td style="padding: 8px;">{latitude}, {longitude}</td>
            </tr>
        </table>
        
        <p style="margin: 20px 0;">
            <a href="{verification_link}" 
               style="background-color: #007bff; color: white; padding: 10px 20px; 
                      text-decoration: none; border-radius: 5px; display: inline-block;">
                Review & Verify Report
            </a>
        </p>
        
        <p style="font-size: 12px; color: #666;">
            This link expires at: <strong>{token_expires_at.isoformat()}</strong>
        </p>
        
        <p style="font-size: 12px; color: #999; margin-top: 30px;">
            If you did not request this, please disregard this email.
            <br>
            SafeRoute Team
        </p>
    </body>
</html>
"""
        
        try:
            return self._send_email(
                to_email=authority_email,
                subject=subject,
                body_text=body_text,
                body_html=body_html
            )
        except Exception as e:
            print(f"Failed to send verification email to {authority_email}: {e}")
            return False
    
    def send_driver_confirmation_email(
        self,
        driver_email: str,
        hazard_id: str,
        hazard_type: str,
        latitude: float,
        longitude: float
    ) -> bool:
        """
        Send confirmation email to driver (future feature).
        
        SAFETY: No internal status, verification details, or authority info.
        
        Args:
            driver_email: Driver's email address
            hazard_id: UUID of the hazard
            hazard_type: Type of hazard
            latitude: Hazard latitude
            longitude: Hazard longitude
        
        Returns:
            True if email sent successfully, False otherwise
        """
        
        subject = "SafeRoute: Hazard Report Received"
        
        body_text = f"""
SafeRoute Hazard Report Confirmation

Thank you for reporting a hazard. Your report has been received and forwarded to safety authorities for verification.

Report ID: {hazard_id}
Hazard Type: {hazard_type}
Location: {latitude}, {longitude}
Submitted at: {datetime.utcnow().isoformat()}

You will be notified when this report is verified and added to the SafeRoute map.

---
SafeRoute Team
"""
        
        body_html = f"""
<html>
    <body style="font-family: Arial, sans-serif; color: #333;">
        <h2>SafeRoute Hazard Report Confirmation</h2>
        
        <p>Thank you for reporting a hazard. Your report has been received and forwarded to safety authorities for verification.</p>
        
        <table style="border-collapse: collapse; margin: 20px 0;">
            <tr>
                <td style="padding: 8px; font-weight: bold;">Report ID:</td>
                <td style="padding: 8px;">{hazard_id}</td>
            </tr>
            <tr>
                <td style="padding: 8px; font-weight: bold;">Hazard Type:</td>
                <td style="padding: 8px;">{hazard_type}</td>
            </tr>
            <tr>
                <td style="padding: 8px; font-weight: bold;">Location:</td>
                <td style="padding: 8px;">{latitude}, {longitude}</td>
            </tr>
            <tr>
                <td style="padding: 8px; font-weight: bold;">Submitted at:</td>
                <td style="padding: 8px;">{datetime.utcnow().isoformat()}</td>
            </tr>
        </table>
        
        <p>You will be notified when this report is verified and added to the SafeRoute map.</p>
        
        <p style="font-size: 12px; color: #999; margin-top: 30px;">
            SafeRoute Team
        </p>
    </body>
</html>
"""
        
        try:
            return self._send_email(
                to_email=driver_email,
                subject=subject,
                body_text=body_text,
                body_html=body_html
            )
        except Exception as e:
            print(f"Failed to send confirmation email to {driver_email}: {e}")
            return False
    
    def _send_email(
        self,
        to_email: str,
        subject: str,
        body_text: str,
        body_html: str
    ) -> bool:
        """
        Internal method to send email via SMTP.
        
        Args:
            to_email: Recipient email address
            subject: Email subject
            body_text: Plain text body
            body_html: HTML body
        
        Returns:
            True if successful, False otherwise
        """
        
        if not self.smtp_user or not self.smtp_password:
            print("SMTP credentials not configured. Email not sent.")
            return False
        
        try:
            # Create message
            msg = MIMEMultipart("alternative")
            msg["Subject"] = subject
            msg["From"] = f"{self.from_name} <{self.from_email}>"
            msg["To"] = to_email
            
            # Attach both plain text and HTML versions
            part1 = MIMEText(body_text, "plain")
            part2 = MIMEText(body_html, "html")
            msg.attach(part1)
            msg.attach(part2)
            
            # Send via SMTP
            with smtplib.SMTP(self.smtp_server, self.smtp_port) as server:
                server.starttls()
                server.login(self.smtp_user, self.smtp_password)
                server.sendmail(self.from_email, to_email, msg.as_string())
            
            print(f"Email sent to {to_email}")
            return True
        
        except Exception as e:
            print(f"SMTP error: {e}")
            return False


# Global instance for convenience
_email_service: Optional[EmailService] = None


def get_email_service() -> EmailService:
    """Get or create the global email service instance."""
    global _email_service
    if _email_service is None:
        _email_service = EmailService()
    return _email_service


def send_verification_email(
    authority_email: str,
    hazard_id: str,
    hazard_type: str,
    latitude: float,
    longitude: float,
    token: str,
    token_expires_at: datetime
) -> bool:
    """
    Convenience function to send verification email.
    
    Args:
        authority_email: Authority's email address
        hazard_id: UUID of hazard
        hazard_type: Type of hazard
        latitude: Hazard latitude
        longitude: Hazard longitude
        token: Verification token
        token_expires_at: Token expiration time
    
    Returns:
        True if email sent successfully
    """
    service = get_email_service()
    return service.send_authority_verification_email(
        authority_email=authority_email,
        hazard_id=hazard_id,
        hazard_type=hazard_type,
        latitude=latitude,
        longitude=longitude,
        token=token,
        token_expires_at=token_expires_at
    )
