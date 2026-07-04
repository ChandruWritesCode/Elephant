import 'package:mobile/pages/profile_setup_page.dart';
import 'package:mobile/providers/basic_providers.dart';
import 'package:mobile/providers/timer_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

class PhoneNumberPage extends StatelessWidget {
  PhoneNumberPage({super.key});

  final TextEditingController numberController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            const Text(
              'Your phone number',
              style: TextStyle(fontSize: 20, fontWeight: .bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Please confirm your country code and enter you phone number. We will send you a verification code via SMS.',
            ),
            SizedBox(height: 20),
            IntlPhoneField(
              initialCountryCode: 'IN',
              controller: numberController,
              decoration: InputDecoration(border: OutlineInputBorder()),
              onChanged: (value) {
                context.read<BasicProviders>().updateConCode(value.countryCode);
                context.read<BasicProviders>().updateNumber(value.number);
                context.read<BasicProviders>().setNumberValid(
                  value.isValidNumber(),
                );
              },
              onCountryChanged: (value) {
                context.read<BasicProviders>().updateConCode(
                  '+${value.dialCode}',
                );
              },
            ),
            Spacer(),
            Container(
              margin: .symmetric(horizontal: 20),
              child: FilledButton(
                style: ButtonStyle(
                  minimumSize: WidgetStatePropertyAll(
                    Size(double.infinity, 40),
                  ),
                ),
                onPressed: context.watch<BasicProviders>().isNumberValid
                    ? () {
                        context.read<BasicProviders>().updateNumber(
                          numberController.text,
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ChangeNotifierProvider(
                              create: (_) => OtpProvider()..startTimer(),
                              child: NumberVerificationPage(),
                            ),
                          ),
                        );
                      }
                    : null,
                child: Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NumberVerificationPage extends StatelessWidget {
  const NumberVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController otpController = TextEditingController();
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: .center,
            crossAxisAlignment: .center,
            children: [
              const Text(
                'Verify your number',
                style: TextStyle(fontWeight: .bold, fontSize: 25),
              ),
              const SizedBox(height: 10),
              Text(
                "We've sent a 6-digit code to\n${context.read<BasicProviders>().getCompleteNumber}",
                textAlign: .center,
              ),
              const SizedBox(height: 25),
              Pinput(
                onChanged: context.read<OtpProvider>().updateOtp,
                controller: otpController,
                length: 6,
                autofocus: true,
                enabled: true,
                focusedPinTheme: PinTheme(
                  width: 50,
                  height: 55,
                  textStyle: TextStyle(fontSize: 25, fontWeight: .w300),
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.blue, width: 3),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    color: Theme.of(context).primaryColor.withAlpha(100),
                  ),
                ),
                defaultPinTheme: PinTheme(
                  width: 50,
                  height: 55,
                  textStyle: TextStyle(fontSize: 25, fontWeight: .w300),
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.grey),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    color: Theme.of(context).primaryColor.withAlpha(100),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              const Text("Didn't receive the code?"),
              Row(
                mainAxisAlignment: .center,
                children: [
                  Icon(Icons.timer_outlined, color: Colors.grey),
                  Consumer<OtpProvider>(
                    builder: (context, otp, child) {
                      return otp.canResend
                          ? TextButton(
                              onPressed: () {
                                otp.resetTimer();
                              },
                              child: const Text('Resend OTP'),
                            )
                          : Text(' ${otp.secondsRemaining}s');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                margin: .symmetric(horizontal: 20),
                child: Consumer<OtpProvider>(
                  builder: (context, otp, child) {
                    return FilledButton(
                      style: ButtonStyle(
                        minimumSize: WidgetStatePropertyAll(
                          Size(double.infinity, 40),
                        ),
                      ),
                      onPressed: otp.isOtpComplete
                          ? () {
                              otp.updateOtp(otpController.text);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileSetupPage(),
                                ),
                              );
                            }
                          : null,
                      child: const Text('Verify'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
