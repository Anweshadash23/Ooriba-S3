import 'dart:convert';
import 'dart:html' as html;

class WebEmailService {
  static const serviceId = 'service_z0soilk';
  static const templateId = 'template_q66bo0j';
  static const userId = '_b8-qaQnQOhviU59X';

  void sendSignUpEmail(String email, String firstName, String lastName) {
    final payload = json.encode({
      'service_id': serviceId,
      'template_id': templateId,
      'user_id': userId,
      'template_params': {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'to_email': email,
        'reply_to': 'anweshadash04@gmail.com',
      },
    });

    final request = html.HttpRequest();
    request
      ..open('POST', 'https://api.emailjs.com/api/v1.0/email/send')
      ..setRequestHeader('Content-Type', 'application/json')
      ..send(payload);

    request.onLoadEnd.listen((_) {
      if (request.status == 200) {
        print('Signup email sent successfully');
      } else {
        print('Failed to send signup email: ${request.responseText}');
      }
    });
  }
}
