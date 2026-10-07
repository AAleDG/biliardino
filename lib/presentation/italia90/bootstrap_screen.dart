import 'package:flutter/material.dart';
import 'widgets/italia90_artwork.dart';
import 'widgets/italia90_components.dart';
import 'widgets/italia90_page.dart';
import 'widgets/italia_graphic_backdrop.dart';

class Italia90BootstrapScreen extends StatelessWidget {
  const Italia90BootstrapScreen({
    super.key,
    required this.hasError,
    required this.onRetry,
  });

  final bool hasError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ItaliaGraphicBackdrop(
        variant: ItaliaBackdropVariant.home,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ItaliaPanel(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandMasthead(mark: ItaliaFootball()),
                    const SizedBox(height: 24),
                    hasError
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.storage_rounded, size: 56),
                              const SizedBox(height: 16),
                              const Text(
                                'Impossibile caricare i dati.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Controlla il dispositivo e riprova.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                key: const ValueKey('bootstrap-retry'),
                                onPressed: onRetry,
                                icon: const Icon(Icons.refresh),
                                label: const Text('RIPROVA'),
                              ),
                            ],
                          )
                        : const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Caricamento dati...'),
                            ],
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
