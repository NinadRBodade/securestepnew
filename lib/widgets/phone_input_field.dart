import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/validators.dart';

/// Custom phone input field with country code selector
class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?, {String countryCode})? validator;
  final String? label;
  final bool enabled;
  final ValueChanged<String>? onCountryCodeChanged;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.validator,
    this.label,
    this.enabled = true,
    this.onCountryCodeChanged,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  String _selectedCountryCode = '+91';

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly, // Only digits allowed
      ],
      decoration: InputDecoration(
        labelText: widget.label ?? 'Phone Number',
        prefixIcon: const Icon(Icons.phone),
        border: const OutlineInputBorder(),
        // Country code selector as prefix
        prefix: _buildCountryCodeSelector(),
        hintText: 'Enter phone number',
      ),
      validator: (value) {
        if (widget.validator != null) {
          return widget.validator!(value, countryCode: _selectedCountryCode);
        }
        return Validators.validatePhone(value, countryCode: _selectedCountryCode);
      },
    );
  }

  Widget _buildCountryCodeSelector() {
    return GestureDetector(
      onTap: widget.enabled ? _showCountryCodePicker : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: widget.enabled ? Colors.grey.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedCountryCode,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: widget.enabled ? Colors.black87 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: widget.enabled ? Colors.black87 : Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  void _showCountryCodePicker() {
    final countryCodes = Validators.getCountryCodes();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Country Code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: countryCodes.length,
                itemBuilder: (context, index) {
                  final country = countryCodes[index];
                  final isSelected = country['code'] == _selectedCountryCode;
                  
                  return ListTile(
                    leading: Text(
                      country['flag']!,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(country['country']!),
                    trailing: Text(
                      country['code']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedCountryCode = country['code']!;
                      });
                      widget.onCountryCodeChanged?.call(_selectedCountryCode);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
