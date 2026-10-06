import React, { useEffect, useRef, useState } from 'react';
import L from 'leaflet';
import { subscribeDrivers, subscribeOrders } from '../services/firestoreService';
import { DriverProfile, OrderItem } from '../types/models';
import { Truck, MapPin, Phone } from 'lucide-react';
import { Badge } from '../components/common/Badge';

export const Tracking: React.FC = () => {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const markersRef = useRef<{ [driverId: string]: L.Marker }>({});

  const [drivers, setDrivers] = useState<DriverProfile[]>([]);
  const [orders, setOrders] = useState<OrderItem[]>([]);
  const [selectedDriver, setSelectedDriver] = useState<DriverProfile | null>(null);

  // Initialize Leaflet Map once
  useEffect(() => {
    if (!mapContainerRef.current || mapInstanceRef.current) return;

    const map = L.map(mapContainerRef.current).setView([31.5204, 74.3587], 12);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap contributors',
      maxZoom: 19,
    }).addTo(map);

    mapInstanceRef.current = map;

    return () => {
      map.remove();
      mapInstanceRef.current = null;
    };
  }, []);

  // Subscribe to real-time driver updates from Firestore
  useEffect(() => {
    const unsubDrivers = subscribeDrivers((data) => {
      setDrivers(data);
    });

    const unsubOrders = subscribeOrders((data) => {
      setOrders(data);
    });

    return () => {
      unsubDrivers();
      unsubOrders();
    };
  }, []);

  // Update map markers when drivers change
  useEffect(() => {
    const map = mapInstanceRef.current;
    if (!map) return;

    // Custom truck icon
    const truckIcon = L.divIcon({
      className: 'custom-truck-icon',
      html: `<div style="background-color: #0369a1; width: 30px; height: 30px; border-radius: 4px; display: flex; align-items: center; justify-content: center; border: 2px solid white; box-shadow: 0 2px 6px rgba(0,0,0,0.3);">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="1" y="3" width="15" height="13"></rect><polygon points="16 8 20 8 23 11 23 16 16 16 16 8"></polygon><circle cx="5.5" cy="18.5" r="2.5"></circle><circle cx="18.5" cy="18.5" r="2.5"></circle></svg>
      </div>`,
      iconSize: [30, 30],
      iconAnchor: [15, 15],
    });

    // Clear old markers
    Object.values(markersRef.current).forEach((m) => m.remove());
    markersRef.current = {};

    drivers.forEach((driver, idx) => {
      const lat = driver.currentLocation?.latitude || driver.latitude || 31.5204 + idx * 0.015;
      const lng = driver.currentLocation?.longitude || driver.longitude || 74.3587 + idx * 0.015;

      const popupContent = `
        <div style="font-family: inherit; padding: 4px; color: #0f172a;">
          <h4 style="margin: 0; font-weight: 700; font-size: 13px;">${driver.name || driver.fullName || 'Fleet Driver'}</h4>
          <p style="margin: 2px 0 0; font-size: 11px; color: #475569;">${driver.vehicleType || 'Commercial Truck'} • Plate: ${driver.vehicleNumber || 'N/A'}</p>
          <p style="margin: 2px 0 0; font-size: 11px; color: #475569;">Phone: ${driver.phone || 'N/A'}</p>
          <div style="margin-top: 6px; padding-top: 4px; border-top: 1px solid #e2e8f0; font-size: 10px; font-weight: 600; color: #0369a1;">
            Status: ${driver.isAvailable ? 'Available for Assignment' : 'Active On Transit'}
          </div>
        </div>
      `;

      const marker = L.marker([lat, lng], { icon: truckIcon })
        .addTo(map)
        .bindPopup(popupContent);

      markersRef.current[driver.id] = marker;
    });
  }, [drivers]);

  const handleSelectDriver = (driver: DriverProfile, idx: number) => {
    setSelectedDriver(driver);
    const map = mapInstanceRef.current;
    if (!map) return;

    const lat = driver.currentLocation?.latitude || driver.latitude || 31.5204 + idx * 0.015;
    const lng = driver.currentLocation?.longitude || driver.longitude || 74.3587 + idx * 0.015;

    map.flyTo([lat, lng], 14, { duration: 1.5 });

    const marker = markersRef.current[driver.id];
    if (marker) {
      marker.openPopup();
    }
  };

  return (
    <div className="space-y-5">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-slate-200 pb-4">
        <div>
          <div className="flex items-center gap-2">
            <MapPin className="w-5 h-5 text-sky-700" />
            <h2 className="text-lg font-bold text-slate-900">Live Fleet Telematics & GPS</h2>
          </div>
          <p className="text-xs text-slate-500 mt-0.5">
            Geospatial tracking of active freight carriers and consignment routes.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <Badge variant="info">
            <span className="w-1.5 h-1.5 rounded-full bg-sky-600 mr-1.5" />
            {drivers.length} Drivers Active on Map
          </Badge>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-4 h-[650px]">
        {/* Left Sidebar: Fleet List */}
        <div className="rounded-lg bg-white border border-slate-200 p-3.5 shadow-2xs flex flex-col h-full overflow-hidden">
          <div className="flex items-center justify-between pb-2.5 border-b border-slate-100">
            <h3 className="text-xs font-bold uppercase tracking-wider text-slate-700">
              Fleet Units ({drivers.length})
            </h3>
            <span className="text-[10px] text-sky-700 font-semibold">Live GPS</span>
          </div>

          <div className="flex-1 overflow-y-auto space-y-2 py-2.5">
            {drivers.length === 0 ? (
              <div className="py-12 text-center text-xs text-slate-500">
                <Truck className="w-6 h-6 mx-auto mb-2 text-slate-400" />
                No active drivers registered in Firestore
              </div>
            ) : (
              drivers.map((d, idx) => (
                <div
                  key={d.id}
                  onClick={() => handleSelectDriver(d, idx)}
                  className={`p-2.5 rounded-md border transition-all cursor-pointer ${
                    selectedDriver?.id === d.id
                      ? 'bg-sky-50 border-sky-300 shadow-xs'
                      : 'bg-slate-50 border-slate-200 hover:bg-slate-100'
                  }`}
                >
                  <div className="flex items-start justify-between">
                    <div>
                      <p className="font-semibold text-slate-900 text-xs">
                        {d.name || d.fullName || 'Fleet Driver'}
                      </p>
                      <p className="text-[11px] text-slate-500 font-mono mt-0.5">
                        {d.vehicleType || 'Truck'} • {d.vehicleNumber || 'Reg Pending'}
                      </p>
                    </div>
                    <Badge variant={d.isAvailable ? 'success' : 'info'} size="sm">
                      {d.isAvailable ? 'Online' : 'On-Trip'}
                    </Badge>
                  </div>

                  <div className="mt-2 pt-1.5 border-t border-slate-200 flex items-center justify-between text-[10px] text-slate-500">
                    <span className="flex items-center gap-1">
                      <Phone className="w-3 h-3 text-slate-400" />
                      {d.phone || '—'}
                    </span>
                    <span className="font-medium text-sky-700">Locate</span>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Right Area: Interactive Map */}
        <div className="lg:col-span-3 rounded-lg bg-white border border-slate-200 overflow-hidden relative shadow-2xs">
          <div ref={mapContainerRef} className="w-full h-full min-h-[480px]" />
        </div>
      </div>
    </div>
  );
};
