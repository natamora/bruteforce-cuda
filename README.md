## Zastosowanie metody brute force przeciwko wybranej metodzie szyfrowania
W ramach przedmiotu **Systemy równoległe i rozproszone** zrealizowano projekt mający na celu zastosowanie metody brute force przeciwko wybranej metodzie szyfrowania z wykorzystaniem architektury CUDA.

### Cel Projektu

- **Przyśpieszenie Kodów Równoległych**: Udowodnienie, że równoległe wykonywanie kodu przy użyciu architektury CUDA może znacząco przyspieszyć działanie programu.
- **Analiza Efektywności**: Przedstawienie, jak zmienia się efektywność i przyśpieszenie algorytmu brute force w zależności od liczby wątków wykorzystywanych w obliczeniach.

### Podsumowanie

Wraz ze zwiększaniem liczby wątków maleje czas znajdowania haseł oraz wzrasta przyśpieszenie. Efektywność, po początkowym wzroście, zaczyna maleć. Zgadza się to z prawem Amdahla, które mówi, że zwiększenie szybkości wykonywania programu w obliczeniach równoległych jest ograniczane przez czas potrzebny na uruchamianie nowych wątków i przydzielanie im zasobów.

Eksperymenty opisane w niniejszym raporcie potwierdzają, że technologia CUDA pozwala na bardzo wydajne wykorzystanie mocy obliczeniowej procesorów graficznych. Kod równoległy może znacząco przyspieszyć czasochłonne obliczenia.

### Raport
Szczegółowy raport z projektu jest dostępny pod poniższym linkiem:

[Raport z projektu](https://drive.google.com/file/d/1pRkzPdHJFGKMZTuMJNH2eQvNTTWAozNU/view?usp=sharing)

## 
All rights reserved
Copyright &copy; Katarzyna Morawska 2019
