import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:toggle_timer/config/colors/app_colors.dart';
import 'package:toggle_timer/config/typography/app_typography.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    this.hintText,
    this.disableAllBorder = false,
    this.isPassword = false,
    this.readOnly = false,
    this.filled = true,
    this.inputFormatters,
    this.enabled = true,
    this.controller,
    this.keyboardType,
    this.validator,
    this.maxLength,
    this.minLines,
    this.maxLines = 1,
    this.initialValue,
    this.errorText,
    this.helperText,
    this.helperMaxLines,
    this.helperStyle,
    this.prefixIcon,
    this.suffixIcon,
    this.fillColor,
    this.hintStyle,
    this.labelText,
    this.labelStyle,
    this.floatingLabelBehavior,
    this.floatingLabelStyle,
    this.errorStyle,
    this.errorMaxLines,
    this.contentPadding,
    this.prefixIconConstraints,
    this.suffixIconConstraints,
    this.counterText,
    this.counterStyle,
    this.focusNode,
    this.onChanged,
    this.onTap,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.onSaved,
    this.autovalidateMode,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.strutStyle,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.autofocus = false,
    this.obscuringCharacter = '•',
    this.autocorrect = true,
    this.smartDashesType,
    this.smartQuotesType,
    this.enableSuggestions = true,
    this.expands = false,
    this.showCursor,
    this.cursorColor,
    this.cursorHeight,
    this.cursorWidth = 2.0,
    this.cursorRadius,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.enableInteractiveSelection = true,
    this.selectionControls,
    this.buildCounter,
    this.scrollPhysics,
    this.scrollController,
    this.restorationId,
    this.enableIMEPersonalizedLearning = true,
    this.border,
    this.enabledBorder,
    this.focusedBorder,
    this.errorBorder,
    this.focusedErrorBorder,
    this.headingLabelText,
    this.headingStyle,
    this.isRequired = false,
    this.disabledBorder,
    this.isPhoneField = false,
  });
  final String? hintText;
  final bool disableAllBorder;
  final bool isPassword;
  final bool readOnly;
  final bool filled;
  final bool enabled;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final int? maxLength;
  final int? minLines;
  final int? maxLines;
  final String? initialValue;
  final String? errorText;
  final String? helperText;
  final int? helperMaxLines;
  final TextStyle? helperStyle;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Color? fillColor;
  final TextStyle? hintStyle;
  final String? labelText;
  final TextStyle? labelStyle;
  final FloatingLabelBehavior? floatingLabelBehavior;
  final TextStyle? floatingLabelStyle;
  final TextStyle? errorStyle;
  final int? errorMaxLines;
  final EdgeInsetsGeometry? contentPadding;
  final BoxConstraints? prefixIconConstraints;
  final BoxConstraints? suffixIconConstraints;
  final String? counterText;
  final TextStyle? counterStyle;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final GestureTapCallback? onTap;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldSetter<String>? onSaved;
  final AutovalidateMode? autovalidateMode;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final bool autofocus;
  final String obscuringCharacter;
  final bool autocorrect;
  final SmartDashesType? smartDashesType;
  final SmartQuotesType? smartQuotesType;
  final bool enableSuggestions;
  final bool expands;
  final bool? showCursor;
  final Color? cursorColor;
  final double? cursorHeight;
  final double cursorWidth;
  final Radius? cursorRadius;
  final EdgeInsets scrollPadding;
  final bool enableInteractiveSelection;
  final TextSelectionControls? selectionControls;
  final InputCounterWidgetBuilder? buildCounter;
  final ScrollPhysics? scrollPhysics;
  final ScrollController? scrollController;
  final String? restorationId;
  final bool enableIMEPersonalizedLearning;
  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final InputBorder? errorBorder;
  final InputBorder? focusedErrorBorder;
  final InputBorder? disabledBorder;
  final String? headingLabelText;
  final TextStyle? headingStyle;
  final List<TextInputFormatter>? inputFormatters;
  final bool isRequired;
  final bool isPhoneField;
  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isPasswordVisible = false;

  // Reusable border configuration
  InputBorder? get _commonBorder => !widget.disableAllBorder
      ? widget.border
      : OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(12));

  InputBorder? get _commonEnabledBorder => !widget.disableAllBorder
      ? widget.enabledBorder
      : OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(12));

  InputBorder? get _commonFocusedBorder => !widget.disableAllBorder
      ? widget.focusedBorder
      : OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(12));

  InputBorder? get _commonErrorBorder => !widget.disableAllBorder
      ? widget.errorBorder
      : OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(12));

  InputBorder? get _commonFocusedErrorBorder => !widget.disableAllBorder
      ? widget.focusedErrorBorder
      : OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(12));

  InputBorder? get _commonDisabledBorder => !widget.disableAllBorder
      ? widget.disabledBorder
      : OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(12));

  // Reusable content padding
  EdgeInsetsGeometry? get _effectiveContentPadding =>
      widget.contentPadding ??
      (widget.hintText?.toLowerCase().contains("search") == true ? const EdgeInsets.symmetric(horizontal: 10) : null);

  // Reusable suffix icon for password fields
  Widget? get _effectiveSuffixIcon => widget.isPassword
      ? IconButton(
          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: AppColors.kAppGrey),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        )
      : widget.suffixIcon;

  // Common input decoration
  InputDecoration get _commonDecoration => InputDecoration(
    hintText: widget.hintText,
    errorText: widget.errorText,
    helperText: widget.helperText,
    helperMaxLines: widget.helperMaxLines,
    helperStyle: widget.helperStyle,
    border: _commonBorder,
    enabledBorder: _commonEnabledBorder,
    focusedBorder: _commonFocusedBorder,
    errorBorder: _commonErrorBorder,
    focusedErrorBorder: _commonFocusedErrorBorder,
    disabledBorder: _commonDisabledBorder,
    prefixIcon: widget.prefixIcon,
    suffixIcon: _effectiveSuffixIcon,
    filled: widget.filled,
    fillColor: Color.fromARGB(255, 69, 69, 69),
    hintStyle: widget.hintStyle ?? AppTypography.style16Regular.copyWith(color: AppColors.kAppGrey),
    labelText: widget.labelText,
    labelStyle: widget.labelStyle,
    floatingLabelBehavior: widget.floatingLabelBehavior,
    floatingLabelStyle: widget.floatingLabelStyle,
    errorStyle: widget.errorStyle,
    errorMaxLines: widget.errorMaxLines,
    contentPadding: _effectiveContentPadding,
    prefixIconConstraints: widget.prefixIconConstraints,
    suffixIconConstraints: widget.suffixIconConstraints,
    counterText: widget.isPhoneField ? "" : widget.counterText,
    counterStyle: widget.counterStyle,
    enabled: widget.enabled,
  );

  // Heading widget
  Widget? get _headingWidget => widget.headingLabelText == null
      ? null
      : Text.rich(
          TextSpan(
            text: widget.headingLabelText,
            style: widget.headingStyle ?? AppTypography.style16Regular,
            children: widget.isRequired
                ? [
                    TextSpan(
                      text: ' *',
                      style: AppTypography.style16Regular.copyWith(color: Colors.red),
                    ),
                  ]
                : [],
          ),
        ).paddingOnly(bottom: 10);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [if (_headingWidget != null) _headingWidget!, _buildTextFormField()],
  );

  Widget _buildTextFormField() => TextFormField(
    controller: widget.controller,
    keyboardType: widget.keyboardType,
    validator: widget.validator,
    maxLength: widget.maxLength,
    minLines: widget.minLines,
    maxLines: widget.maxLines,
    initialValue: widget.initialValue,
    obscureText: widget.isPassword && !_isPasswordVisible,
    readOnly: widget.readOnly,
    enabled: widget.enabled,
    focusNode: widget.focusNode,
    onChanged: widget.onChanged,
    cursorColor: AppColors.kAppWhite,
    onTap: widget.onTap,
    onEditingComplete: widget.onEditingComplete,
    onFieldSubmitted: widget.onFieldSubmitted,
    onSaved: widget.onSaved,
    autovalidateMode: widget.autovalidateMode,
    textInputAction: widget.textInputAction,
    textCapitalization: widget.textCapitalization,
    style: widget.style ?? AppTypography.style16Regular.copyWith(color: AppColors.kAppWhite),
    strutStyle: widget.strutStyle,
    textAlign: widget.textAlign,
    textAlignVertical: widget.textAlignVertical,
    autofocus: widget.autofocus,
    obscuringCharacter: widget.obscuringCharacter,
    autocorrect: widget.autocorrect,
    smartDashesType: widget.smartDashesType,
    smartQuotesType: widget.smartQuotesType,
    enableSuggestions: widget.enableSuggestions,
    expands: widget.expands,
    showCursor: widget.showCursor,
    cursorHeight: widget.cursorHeight,
    cursorWidth: widget.cursorWidth,
    cursorRadius: widget.cursorRadius,
    scrollPadding: widget.scrollPadding,
    enableInteractiveSelection: widget.enableInteractiveSelection,
    selectionControls: widget.selectionControls,
    buildCounter: widget.buildCounter,
    scrollPhysics: widget.scrollPhysics,
    scrollController: widget.scrollController,
    inputFormatters: widget.inputFormatters,
    restorationId: widget.restorationId,
    enableIMEPersonalizedLearning: widget.enableIMEPersonalizedLearning,
    decoration: _commonDecoration,
  );
}
