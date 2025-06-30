# 🧩 DLL Kaynak Kodları ve Derlenmiş Dosyalar

Bu klasör, uygulamanın kullandığı DLL dosyalarının kaynak kodlarını ve derlenmiş hallerini içerir.

---

## 📁 getScreenShoot.dll

### Açıklama:
- Ekranın belirli bir bölgesinden ekran görüntüsü alır.
- Videonun geçiş noktalarını belirlemede kullanılır.

### Yol:
- Kaynak kod: `getScreenShoot/`
- Derlenmiş DLL: `getScreenShoot.dll`

---

## 📁 OpenCVWrapper.dll

### Açıklama:
- OpenCV kullanarak görüntü işleme işlevlerini dışa aktarır.
- Örneğin: iki görüntü arasındaki farkı hesaplama, maskeleme, karşılaştırma gibi işlemler.

### Yol:
- Kaynak kod: `OpenCVWrapper/`
- Derlenmiş DLL: `OpenCVWrapper.dll`

---

## 🧱 Bağımlılıklar

Her iki DLL de aşağıdaki OpenCV runtime dosyasına ihtiyaç duyar:

Release sürümü için:
- `opencv_world4110.dll` (OpenCV 4.1.1)
> build>windows>x64>runner>Release 

Debug sürümü için:
- `opencv_world4110d.dll` (OpenCV 4.1.1)

> build>windows>x64>runner>Debug 


Bu DLL’leri uygulamayı çalıştırmadan gereken konumlara 1'er kopyasını eklemeyi unutmayın.