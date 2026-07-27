import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'info_tooltip.dart';
import '../theme/app_colors.dart';

class InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final bool autoValidate;
  final String? tooltip;

  /// Texto de hint personalizado. Si no se provee, usa "Ej: 35.5".
  final String? hintText;

  final String? Function(double value)? extraValidator;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final VoidCallback? onSubmit;

  const InputField({
    super.key,
    required this.controller,
    required this.label,
    this.enabled = true,
    this.autoValidate = false,
    this.tooltip,
    this.hintText,
    this.extraValidator,
    this.focusNode,
    this.nextFocusNode,
    this.onSubmit,
  });

  String? validar(String value) {
    if (!enabled) return null;
    if (value.isEmpty) return 'Campo requerido';
    final number = double.tryParse(value);
    if (number == null) return 'Número inválido';
    if (number < 0) return 'No puede ser negativo';
    if (extraValidator != null) return extraValidator!(number);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        focusNode: focusNode,
        textInputAction: onSubmit != null
            ? TextInputAction.done
            : (nextFocusNode != null
                ? TextInputAction.next
                : TextInputAction.done),
        onFieldSubmitted: (_) {
          if (onSubmit != null) {
            onSubmit!();
          } else if (nextFocusNode != null) {
            nextFocusNode!.requestFocus();
          }
        },
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        autovalidateMode: autoValidate
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        validator: enabled ? (value) => validar(value ?? '') : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: enabled ? (hintText ?? 'Ej: 35.5') : 'No aplica',
          filled: true,
          fillColor:
              enabled ? context.appColors.inputFill : Colors.grey.shade100,
          suffixIcon: (tooltip != null && enabled)
              ? InfoTooltip(message: tooltip!)
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: context.appColors.inputFocused,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
        ),
      ),
    );
  }
}
