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
      html: `<div style="background-color: #0284c7; width: 34px; height: 34px; border-radius: 50%; display: flex; align-items: center; justify-content: center; border: 2px solid white; box-shadow: 0 4px 12px rgba(2,132,199,0.5);">
        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="1" y="3" width="15" height="13"></rect><polygon points="16 8 20 8 23 11 23 16 16 16 16 8"></polygon><circle cx="5.5" cy="18.5" r="2.5"></circle><circle cx="18.5" cy="18.5" r="2.5"></circle></svg>
      </div>`,
      iconSize: [34, 34],
      iconAnchor: [17, 17],
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
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <MapPin className="w-6 h-6 text-sky-400" />
            <h2 className="text-2xl font-black text-white">Live Fleet Telematics & GPS</h2>
          </div>
          <p className="text-xs text-slate-400 mt-1">
            Real-time geospatial tracking of active freight carriers and consignment routes.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <Badge variant="info">
            <span className="w-2 h-2 rounded-full bg-sky-400 animate-ping mr-1.5" />
            {drivers.length} Drivers Active on Map
          </Badge>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6 h-[700px]">
        {/* Left Sidebar: Fleet List */}
        <div className="rounded-2xl bg-slate-900/60 border border-slate-800 p-4 backdrop-blur-xl flex flex-col h-full overflow-hidden">
          <div className="flex items-center justify-between pb-3 border-b border-slate-800">
            <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400">
              Fleet Units ({drivers.length})
            </h3>
            <span className="text-[10px] text-sky-400 font-semibold">Live GPS</span>
          </div>

          <div className="flex-1 overflow-y-auto space-y-2 py-3">
            {drivers.length === 0 ? (
              <div className="py-12 text-center text-xs text-slate-500">
                <Truck className="w-8 h-8 mx-auto mb-2 text-slate-700" />
                No active drivers registered in Firestore
              </div>
            ) : (
              drivers.map((d, idx) => (
                <div
                  key={d.id}
                  onClick={() => handleSelectDriver(d, idx)}
                  className={`p-3 rounded-xl border transition-all cursor-pointer ${
                    selectedDriver?.id === d.id
                      ? 'bg-sky-500/15 border-sky-500/40 shadow-lg'
                      : 'bg-slate-950/60 border-slate-800 hover:border-slate-700'
                  }`}
                >
                  <div className="flex items-start justify-between">
                    <div>
                      <p className="font-semibold text-white text-xs">
                        {d.name || d.fullName || 'Fleet Driver'}
                      </p>
                      <p className="text-[11px] text-slate-400 font-mono mt-0.5">
                        {d.vehicleType || 'Truck'} • {d.vehicleNumber || 'Reg Pending'}
                      </p>
                    </div>
                    <Badge variant={d.isAvailable ? 'success' : 'info'} size="sm">
                      {d.isAvailable ? 'Online' : 'On-Trip'}
                    </Badge>
                  </div>

                  <div className="mt-2 pt-2 border-t border-slate-800/80 flex items-center justify-between text-[10px] text-slate-400">
                    <span className="flex items-center gap-1">
                      <Phone className="w-3 h-3 text-slate-500" />
                      {d.phone || '—'}
                    </span>
                    <span className="font-mono text-sky-400">Click to Locate</span>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Right Area: Interactive Map */}
        <div className="lg:col-span-3 rounded-2xl bg-slate-900 border border-slate-800 overflow-hidden relative shadow-2xl">
          <div ref={mapContainerRef} className="w-full h-full min-h-[500px]" />
        </div>
      </div>
    </div>
  );
};
