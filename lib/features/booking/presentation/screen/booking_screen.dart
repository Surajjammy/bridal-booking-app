import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:makeup_booking_app/utils/app_text_styles.dart';
import 'package:makeup_booking_app/utils/color_resource.dart';

import '../../../artist/domain/entity/artist.dart';
import '../provider/booking_provider.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final Artist artist;

  const BookingScreen({super.key, required this.artist});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  DateTime? selectedDate;
  String? selectedTime;
  bool isLoading = false;

  final List<String> timeSlots = [
    "10:00 AM",
    "12:00 PM",
    "2:00 PM",
    "4:00 PM",
    "6:00 PM",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(
            Icons.chevron_left,
            color: Colors.white,
          ),
        ),
        title: Text(
          widget.artist.name,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 📅 DATE SECTION
            const Text(
              "Select Date",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );

                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                  });
                }
              },
              child: Text(
                selectedDate == null
                    ? "Choose Date"
                    : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
              ),
            ),

            const SizedBox(height: 25),

            /// ⏰ TIME SECTION
            const Text(
              "Select Time",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: timeSlots.map((time) {
                final isSelected = selectedTime == time;

                return ChoiceChip(
                  checkmarkColor:
                      isSelected ? Colors.white : Colors.transparent,
                  label: Text(
                    time,
                    style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : ColorResource.colorCards),
                  ),
                  selected: isSelected,
                  selectedColor: ColorResource.colorRoseGoldCTA,
                  onSelected: (_) {
                    setState(() {
                      selectedTime = time;
                    });
                  },
                );
              }).toList(),
            ),

            const Spacer(),

            /// 🔥 CONFIRM BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorResource.colorRoseGoldCTA,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        if (selectedDate == null || selectedTime == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Select date & time"),
                            ),
                          );
                          return;
                        }

                        setState(() => isLoading = true);

                        try {
                          final datasource =
                              ref.read(bookingDatasourceProvider);

                          await datasource.saveBooking(
                            artistName: widget.artist.name,
                            date:
                                "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                            time: selectedTime!,
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Booking Confirmed 🎉"),
                              ),
                            );

                            Navigator.popUntil(
                                context, (route) => route.isFirst);
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Error: $e"),
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => isLoading = false);
                          }
                        }
                      },
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Confirm Booking",
                        style: AppTextStyles.button,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
