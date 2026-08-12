import 'package:flutter/material.dart';

import '../customer_controller.dart';
import '../customer_ui.dart';
import '../domain.dart';

const Color _primary = Color(0xFF078A27);
const Color _primaryLight = Color(0xFFE9F7EA);
const Color _background = Color(0xFFFCFCFA);
const Color _border = Color(0xFFE7E9E4);
const Color _text = Color(0xFF111310);
const Color _mutedText = Color(0xFF686C66);

enum _OrderFilter { all, ongoing, completed, cancelled }

class OrdersPage extends StatefulWidget {
  const OrdersPage({required this.controller, super.key});

  final CustomerController controller;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  _OrderFilter _selectedFilter = _OrderFilter.all;

  List<CustomerOrder> get _visibleOrders {
    if (_selectedFilter == _OrderFilter.all) return widget.controller.orders;
    return widget.controller.orders
        .where(
          (CustomerOrder order) =>
              _filterForStatus(order.status) == _selectedFilter,
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final CustomerController controller = widget.controller;
    final List<CustomerOrder> orders = _visibleOrders;
    final bool initialLoading =
        controller.loadingOrders && controller.orders.isEmpty;

    return ColoredBox(
      color: _background,
      child: RefreshIndicator(
        color: _primary,
        onRefresh: controller.loadOrders,
        child: CustomScrollView(
          key: const PageStorageKey<String>('orders-scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _FilterBar(
                  selected: _selectedFilter,
                  orders: controller.orders,
                  onSelected: (_OrderFilter filter) {
                    setState(() => _selectedFilter = filter);
                  },
                ),
              ),
            ),
            if (controller.loadingOrders && controller.orders.isNotEmpty)
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(3)),
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: _primary,
                      backgroundColor: _primaryLight,
                    ),
                  ),
                ),
              ),
            if (controller.ordersError != null && controller.orders.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _OrdersError(
                    message: controller.ordersError!,
                    onRetry: controller.loadOrders,
                  ),
                ),
              ),
            if (initialLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _LoadingOrders(),
              )
            else if (controller.ordersError != null &&
                controller.orders.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 30),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _OrdersError(
                      message: controller.ordersError!,
                      onRetry: controller.loadOrders,
                    ),
                  ),
                ),
              )
            else if (controller.orders.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _NoOrders(filter: _OrderFilter.all),
              )
            else if (orders.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _NoOrders(filter: _selectedFilter),
              )
            else ...<Widget>[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverList.separated(
                  itemCount: orders.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int index) =>
                      _OrderCard(order: orders[index]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
                sliver: SliverToBoxAdapter(
                  child: _OrderHelpCard(
                    order: orders.first,
                    store: controller.selectedStore!,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.orders,
    required this.onSelected,
  });

  final _OrderFilter selected;
  final List<CustomerOrder> orders;
  final ValueChanged<_OrderFilter> onSelected;

  int _countFor(_OrderFilter filter) {
    if (filter == _OrderFilter.all) return orders.length;
    return orders
        .where(
          (CustomerOrder order) => _filterForStatus(order.status) == filter,
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _OrderFilter.values.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 9),
        itemBuilder: (BuildContext context, int index) {
          final _OrderFilter filter = _OrderFilter.values[index];
          final bool isSelected = filter == selected;
          return Semantics(
            button: true,
            selected: isSelected,
            label: '${_filterLabel(filter)}, ${_countFor(filter)} orders',
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onSelected(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryLight : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? _primaryLight : _border,
                  ),
                ),
                child: Text(
                  _filterLabel(filter),
                  style: TextStyle(
                    color: isSelected ? _primary : _text,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final _StatusDisplay status = _statusDisplay(order.status);
    final List<CustomerOrderItem> visibleItems = order.items
        .take(4)
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Order #${order.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(order.createdAt),
                      style: const TextStyle(
                        color: _mutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(status: status),
            ],
          ),
          const SizedBox(height: 18),
          if (status.cancelled)
            _CancelledStatus(reason: order.rejectionReason)
          else
            _StatusTimeline(step: status.step),
          const SizedBox(height: 19),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 15),
          if (visibleItems.isEmpty)
            const Text(
              'Item details unavailable',
              style: TextStyle(color: _mutedText, fontSize: 12),
            )
          else
            ...visibleItems.map(
              (CustomerOrderItem item) => Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${item.name} (${item.packSize}) \u00D7 ${item.quantity}',
                        style: const TextStyle(
                          color: _text,
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      _formatMoney(item.price * item.quantity),
                      style: const TextStyle(
                        color: _text,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (order.items.length > visibleItems.length) ...<Widget>[
            Text(
              '+${order.items.length - visibleItems.length} more items',
              style: const TextStyle(
                color: _primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 13),
          ],
          Row(
            children: <Widget>[
              const Text(
                'Payment',
                style: TextStyle(
                  color: _mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                _paymentLabel(order.paymentMethod),
                style: const TextStyle(
                  color: _text,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              const Text(
                'Total',
                style: TextStyle(
                  color: _text,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                _formatMoney(order.total),
                style: const TextStyle(
                  color: _text,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final _StatusDisplay status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(status.icon, color: status.color, size: 14),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.step});

  final int step;

  static const List<String> _labels = <String>[
    'Placed',
    'Accepted',
    'Packing',
    'On the way',
    'Delivered',
  ];
  static const List<IconData> _icons = <IconData>[
    Icons.check_rounded,
    Icons.thumb_up_alt_outlined,
    Icons.inventory_2_outlined,
    Icons.local_shipping_outlined,
    Icons.favorite_border_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final int safeStep = step.clamp(0, _labels.length - 1);
    return Semantics(
      label: 'Order progress: ${_labels[safeStep]}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List<Widget>.generate(_labels.length, (int index) {
          final bool reached = index <= safeStep;
          return Expanded(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index == 0
                            ? Colors.transparent
                            : index <= safeStep
                            ? _primary
                            : _border,
                      ),
                    ),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: reached ? _primary : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: reached ? _primary : _border),
                      ),
                      child: Icon(
                        _icons[index],
                        size: 13,
                        color: reached ? Colors.white : _mutedText,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index == _labels.length - 1
                            ? Colors.transparent
                            : index < safeStep
                            ? _primary
                            : _border,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  _labels[index],
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: reached ? _primary : _mutedText,
                    fontSize: 9,
                    height: 1.15,
                    fontWeight: reached ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _CancelledStatus extends StatelessWidget {
  const _CancelledStatus({this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    final String message = (reason?.trim().isNotEmpty ?? false)
        ? reason!.trim()
        : 'This order was cancelled.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFC62828),
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF8F1F19),
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderHelpCard extends StatelessWidget {
  const _OrderHelpCard({required this.order, required this.store});

  final CustomerOrder order;
  final CustomerStore store;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          showCustomerStoreContactSheet(
            context,
            store: store,
            orderId: order.id,
          );
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: <Widget>[
              Icon(Icons.help_outline_rounded, color: _text, size: 21),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Need help with this order?',
                      style: TextStyle(
                        color: _text,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Store contact details',
                      style: TextStyle(color: _mutedText, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: _text, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusDisplay {
  const _StatusDisplay({
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
    required this.step,
    this.cancelled = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color background;
  final int step;
  final bool cancelled;
}

_StatusDisplay _statusDisplay(String raw) {
  final String status = _normalizeStatus(raw);
  return switch (status) {
    'NEW' => const _StatusDisplay(
      label: 'Order placed',
      icon: Icons.circle,
      color: Color(0xFFF29900),
      background: Color(0xFFFFF2D5),
      step: 0,
    ),
    'ACCEPTED' => const _StatusDisplay(
      label: 'Accepted',
      icon: Icons.check_circle_rounded,
      color: _primary,
      background: _primaryLight,
      step: 1,
    ),
    'PREPARING' => const _StatusDisplay(
      label: 'Packing',
      icon: Icons.inventory_2_rounded,
      color: _primary,
      background: _primaryLight,
      step: 2,
    ),
    'READY' => const _StatusDisplay(
      label: 'Ready',
      icon: Icons.shopping_bag_rounded,
      color: _primary,
      background: _primaryLight,
      step: 2,
    ),
    'OUT_FOR_DELIVERY' => const _StatusDisplay(
      label: 'On the way',
      icon: Icons.local_shipping_rounded,
      color: _primary,
      background: _primaryLight,
      step: 3,
    ),
    'DELIVERED' => const _StatusDisplay(
      label: 'Delivered',
      icon: Icons.check_circle_rounded,
      color: _primary,
      background: _primaryLight,
      step: 4,
    ),
    'CANCELLED' ||
    'CANCELED' ||
    'REJECTED' ||
    'DECLINED' => const _StatusDisplay(
      label: 'Cancelled',
      icon: Icons.cancel_rounded,
      color: Color(0xFFC62828),
      background: Color(0xFFFFE9E7),
      step: 0,
      cancelled: true,
    ),
    _ => const _StatusDisplay(
      label: 'Updating',
      icon: Icons.sync_rounded,
      color: _primary,
      background: _primaryLight,
      step: 0,
    ),
  };
}

_OrderFilter _filterForStatus(String raw) {
  final String status = _normalizeStatus(raw);
  if (status == 'DELIVERED') return _OrderFilter.completed;
  if (<String>{
    'CANCELLED',
    'CANCELED',
    'REJECTED',
    'DECLINED',
  }.contains(status)) {
    return _OrderFilter.cancelled;
  }
  return _OrderFilter.ongoing;
}

String _normalizeStatus(String raw) => raw
    .trim()
    .toUpperCase()
    .replaceAll('ORDERSTATUS.', '')
    .replaceAll('NEW_ORDER', 'NEW')
    .replaceAll('NEWORDER', 'NEW')
    .replaceAll('-', '_')
    .replaceAll(' ', '_');

String _filterLabel(_OrderFilter filter) => switch (filter) {
  _OrderFilter.all => 'All',
  _OrderFilter.ongoing => 'Ongoing',
  _OrderFilter.completed => 'Completed',
  _OrderFilter.cancelled => 'Cancelled',
};

String _paymentLabel(String value) {
  final String normalized = value.trim().toUpperCase();
  if (normalized == 'COD' || normalized == 'CASH_ON_DELIVERY') return 'COD';
  return normalized.isEmpty ? 'Not available' : normalized.replaceAll('_', ' ');
}

String _formatMoney(num value) {
  final bool hasPaise = value % 1 != 0;
  final String raw = value.toStringAsFixed(hasPaise ? 2 : 0);
  final List<String> parts = raw.split('.');
  final String digits = parts.first;
  if (digits.length <= 3) return '\u20B9$raw';

  final String tail = digits.substring(digits.length - 3);
  String head = digits.substring(0, digits.length - 3);
  final List<String> groups = <String>[];
  while (head.length > 2) {
    groups.insert(0, head.substring(head.length - 2));
    head = head.substring(0, head.length - 2);
  }
  if (head.isNotEmpty) groups.insert(0, head);
  final String formatted = '${groups.join(',')},$tail';
  return parts.length == 2
      ? '\u20B9$formatted.${parts[1]}'
      : '\u20B9$formatted';
}

String _formatDate(DateTime value) {
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final DateTime local = value.toLocal();
  final String minute = local.minute.toString().padLeft(2, '0');
  final int hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final String period = local.hour >= 12 ? 'PM' : 'AM';
  return '${local.day} ${months[local.month - 1]} ${local.year} \u2022 '
      '$hour12:$minute $period';
}

class _OrdersError extends StatelessWidget {
  const _OrdersError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD8D4)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.cloud_off_outlined,
            color: Color(0xFFC62828),
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _text, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: _primary),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _LoadingOrders extends StatelessWidget {
  const _LoadingOrders();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: 80),
        child: SizedBox.square(
          dimension: 28,
          child: CircularProgressIndicator(color: _primary, strokeWidth: 2.5),
        ),
      ),
    );
  }
}

class _NoOrders extends StatelessWidget {
  const _NoOrders({required this.filter});

  final _OrderFilter filter;

  @override
  Widget build(BuildContext context) {
    final bool all = filter == _OrderFilter.all;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 30, 28, 90),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: _primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: _primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              all
                  ? 'No orders yet'
                  : 'No ${_filterLabel(filter).toLowerCase()} orders',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              all
                  ? 'Your placed orders and live updates will appear here.'
                  : 'Orders matching this filter will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _mutedText,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
