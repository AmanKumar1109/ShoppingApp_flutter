import 'package:flutter/material.dart';
import 'voice_search_bottom_sheet.dart';

class CustomSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final ValueChanged<String>? onVoiceResult;
  final String hintText;
  final bool enableVoiceSearch;
  final bool readOnly;
  final VoidCallback? onTap;

  const CustomSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.onVoiceResult,
    this.hintText = 'Search groceries, meals or essentials',
    this.enableVoiceSearch = true,
    this.readOnly = false,
    this.onTap,
  });

  @override
  State<CustomSearchField> createState() => _CustomSearchFieldState();
}

class _CustomSearchFieldState extends State<CustomSearchField> {
  late final TextEditingController _internalController;
  bool _isInternal = false;

  TextEditingController get _effectiveController =>
      widget.controller ?? _internalController;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = TextEditingController();
      _isInternal = true;
    }
  }

  @override
  void dispose() {
    if (_isInternal) {
      _internalController.dispose();
    }
    super.dispose();
  }

  Future<void> _handleVoiceSearch() async {
    final query = await VoiceSearchBottomSheet.show(
      context,
      initialHint: widget.hintText,
    );

    if (query != null && query.trim().isNotEmpty) {
      final cleanQuery = query.trim();
      _effectiveController.text = cleanQuery;
      _effectiveController.selection = TextSelection.fromPosition(
        TextPosition(offset: cleanQuery.length),
      );
      widget.onChanged?.call(cleanQuery);
      widget.onSubmitted?.call(cleanQuery);
      widget.onVoiceResult?.call(cleanQuery);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _effectiveController,
        focusNode: widget.focusNode,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        onChanged: (val) {
          setState(() {});
          widget.onChanged?.call(val);
        },
        onSubmitted: widget.onSubmitted,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF152C1E),
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey[600],
            size: 22,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_effectiveController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                  onPressed: () {
                    _effectiveController.clear();
                    setState(() {});
                    widget.onChanged?.call('');
                    widget.onClear?.call();
                  },
                ),
              if (widget.enableVoiceSearch)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: _handleVoiceSearch,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7C415).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        color: Color(0xFF19251B),
                        size: 18,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}
