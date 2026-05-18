import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Códigos de país soportados
enum CountryCode {
  mx(code: '+52', flag: '🇲🇽', label: 'México (+52)', digits: 10),
  us(code: '+1', flag: '🇺🇸', label: 'EE.UU. (+1)', digits: 10);

  final String code;
  final String flag;
  final String label;
  final int digits;

  const CountryCode({
    required this.code,
    required this.flag,
    required this.label,
    required this.digits,
  });
}

class PhoneField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final String? initialPhone;
  final void Function(CountryCode)? onCountryChanged;

  const PhoneField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.initialPhone,
    this.onCountryChanged,
  });

  @override
  State<PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<PhoneField> {
  CountryCode _selected = CountryCode.mx;

  @override
  void initState() {
    super.initState();
    // Detectar código de país del teléfono existente al editar
    if (widget.initialPhone != null) {
      final phone = widget.initialPhone!;
      if (phone.startsWith('+1') ||
          phone.startsWith('1') && phone.length == 11) {
        _selected = CountryCode.us;
        // Dejar solo los dígitos sin el código en el controller
        widget.controller.text = phone.replaceAll(RegExp(r'^\+?1'), '');
      } else if (phone.startsWith('+52') || phone.startsWith('52')) {
        _selected = CountryCode.mx;
        widget.controller.text = phone.replaceAll(RegExp(r'^\+?52'), '');
      }
    }
  }

  /// Retorna el teléfono normalizado con código de país: +521234567890
  String get normalizedPhone {
    final digits = widget.controller.text.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return '${_selected.code}$digits';
  }

  String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El teléfono es requerido';
    }
    final digits = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (digits.length != _selected.digits) {
      return 'Ingresa ${_selected.digits} dígitos para ${_selected.label}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-\(\)]')),
      ],
      decoration: InputDecoration(
        labelText: 'Teléfono (WhatsApp) *',
        helperText: 'Se usará para enviar recordatorios',
        // Selector de código de país como prefijo
        prefixIcon: InkWell(
          onTap: widget.enabled ? _showCountryPicker : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_selected.flag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 4),
                Text(
                  _selected.code,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 18),
              ],
            ),
          ),
        ),
      ),
      validator: validate,
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Seleccionar país',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              ...CountryCode.values.map(
                (country) => ListTile(
                  leading: Text(
                    country.flag,
                    style: const TextStyle(fontSize: 28),
                  ),
                  title: Text(country.label),
                  trailing: _selected == country
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    setState(() => _selected = country);
                    widget.onCountryChanged?.call(country);
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

String normalizePhoneWithCode(String rawPhone, CountryCode country) {
  final digits = rawPhone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  return '${country.code}$digits';
}