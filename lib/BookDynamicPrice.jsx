import React, { useState, useEffect, useMemo } from 'react';
import { toast } from 'react-toastify';
import axios from 'axios';
import { jwtDecode } from 'jwt-decode';
import InputSuggestion from './InputSuggestion';
import { useGetAllDiscountCouponsQuery } from '../../../lib/api/apiSlice'; 

const BookDynamicPrice = ({ formState, setFormState, onSuccess }) => {
  const [shipperSearch, setShipperSearch] = useState('');
  const [shipperResults, setShipperResults] = useState([]);
  const [showShipperOptions, setShowShipperOptions] = useState(false);
  const today = new Date();
  const todayStr = today.toISOString().split('T')[0];
  const [pickupDateMin, setPickupDateMin] = useState(todayStr);
  const [dcClosingTime, setDcClosingTime] = useState(null);
  const [consigneeSearch, setConsigneeSearch] = useState('');
  const [consigneeResults, setConsigneeResults] = useState([]);
  const [showConsigneeOptions, setShowConsigneeOptions] = useState(false);
  const [couponCode, setCouponCode] = useState('');
  const [couponApplied, setCouponApplied] = useState(null);
  const [couponDiscount, setCouponDiscount] = useState(0);
  const [isValidatingCoupon, setIsValidatingCoupon] = useState(false);
  const [couponValidationError, setCouponValidationError] = useState(null);
  const {
    data: allCoupons,
    isLoading: isLoadingCoupons,
    error: couponError,
  } = useGetAllDiscountCouponsQuery();
  const activeCoupons = useMemo(() => {
    return (allCoupons || []).filter(c => c.is_active);
  }, [allCoupons]);
  const [challanFiles, setChallanFiles] = useState([]);
  const [totalUnits, setTotalUnits] = useState(0);
  const [grossWeight, setGrossWeight] = useState(0);
  const [volumetricWeight, setVolumetricWeight] = useState(0);
  const [totalVolume, setTotalVolume] = useState(0);
  const [chargeableWeight, setChargeableWeight] = useState(0);
  const [preTaxAmount, setPreTaxAmount] = useState(0);
  const [transport_amount, setTransportAmount] = useState(0);
  const [gstAmount, setGstAmount] = useState(0);
  const [finalPayable, setFinalPayable] = useState(0);
  const [savedDimensions, setSavedDimensions] = useState([]);
  const [selectedSavedDim, setSelectedSavedDim] = useState('');
  const [showSaveDimModal, setShowSaveDimModal] = useState(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [newDimName, setNewDimName] = useState('');
  const [dimToDelete, setDimToDelete] = useState(null);

  const timeStramp = [
    "08:00AM to 10:00 AM",
    "09:00AM to 11:00 AM",
    "10:00 AM to 12:00 PM",
    "11:00 AM to 01:00 PM",
    "12:00 PM to 02:00 PM",
  ];

  const toNumber = (val) => (val !== null && val !== undefined && !isNaN(val) ? Number(val) : 0);

  const setField = (field, value) => setFormState(prev => ({ ...prev, [field]: value }));

  const handleToggle = (type) => (event) => {
    const isChecked = event.target.checked;
    setFormState((prevState) => ({
      ...prevState,
      toggles: {
        ...prevState.toggles,
        [type]: isChecked,
      },
    }));
  };

  const handleChallanUpload = (e) => {
    const newFiles = Array.from(e.target.files);
    setChallanFiles((prevFiles) => [...prevFiles, ...newFiles]);
  };

  const handleRemoveChallanFile = (indexToRemove) => {
    setChallanFiles((prevFiles) => prevFiles.filter((_, index) => index !== indexToRemove));
  };

  const handleSaveDimensionsClick = () => {
    if (formState.dimensions.length === 0) {
      toast.error('No dimensions to save');
      return;
    }
    setNewDimName('');
    setShowSaveDimModal(true);
  };

  const fetchSavedDimensionsFromApi = async () => {
    try {
      const token = localStorage.getItem('token');
      if (!token) return;
      const decoded = jwtDecode(token);
      const customerId = decoded.customer_id || decoded.id || decoded.user_id;
      if (!customerId) return;
      const res = await axios.get(`${import.meta.env.VITE_BASE_URL}/api/dynamic-price-manager/saved-dimensions/${customerId}`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const rows = res.data?.data || [];
      const grouped = {};
      rows.forEach(r => {
        const name = r.dimension_name || (`dim-${r.id}`);
        if (!grouped[name]) grouped[name] = { id: name, name, dimensions: [] };
        grouped[name].dimensions.push({
          id: r.id,
          length: Number(r.length) || 0,
          breadth: Number(r.breadth) || 0,
          height: Number(r.height) || 0,
          units: r.units ? Number(r.units) : 1,
          perUnitWeight: Number(r.weight) || 0,
          unit_type: r.unit_type || ''
        });
      });
      const result = Object.values(grouped).map(g => ({ id: g.id, name: g.name, dimensions: g.dimensions }));
      setSavedDimensions(result);
      localStorage.setItem('savedDimensions', JSON.stringify(result));
    } catch (err) {
      const savedDims = localStorage.getItem('savedDimensions');
      if (savedDims) {
        try {
          setSavedDimensions(JSON.parse(savedDims));
        } catch (e) {
          setSavedDimensions([]);
        }
      } else {
        setSavedDimensions([]);
      }
    }
  };

  const saveCurrentDimensions = async () => {
    if (!newDimName.trim()) {
      toast.error('Please enter a name for these dimensions');
      return;
    }
    const isConfirmed = window.confirm('Are you sure you want to save dimensions?');
    if (!isConfirmed) return;
    try {
      const token = localStorage.getItem('token');
      if (!token) throw new Error('Token not found');
      const decoded = jwtDecode(token);
      const customerId = decoded.customer_id || decoded.id || decoded.user_id;
      if (!customerId) throw new Error('Customer ID not found in token');
      const url = `${import.meta.env.VITE_BASE_URL}/api/dynamic-price-manager/saved-dimensions`;
      const requests = formState.dimensions.map(dim => {
        const payload = {
          customer_id: customerId,
          dimension_name: newDimName.trim(),
          length: dim.length || 0,
          breadth: dim.breadth || 0,
          height: dim.height || 0,
          weight: dim.perUnitWeight || dim.weight || 0,
          unit_type: dim.unit_type || 'carton'
        };
        return axios.post(url, payload, { headers: { Authorization: `Bearer ${token}` } });
      });
      await Promise.all(requests);
      await fetchSavedDimensionsFromApi();
      setShowSaveDimModal(false);
      toast.success('Dimensions saved successfully!');
    } catch (err) {
      toast.error('Failed to save dimensions');
    }
  };

  useEffect(() => {
    const savedDims = localStorage.getItem('savedDimensions');
    if (savedDims) {
      try {
        setSavedDimensions(JSON.parse(savedDims));
      } catch (e) {
        setSavedDimensions([]);
      }
    }
    fetchSavedDimensionsFromApi();
  }, []);

  const handleDimensionSelect = (e) => {
    const dimId = e.target.value;
    if (!dimId) return;
    const selectedDim = savedDimensions.find(dim => dim.id.toString() === dimId);
    if (selectedDim) {
      setFormState(prev => ({
        ...prev,
        dimensions: selectedDim.dimensions.map(dim => ({
          id: Date.now() + Math.floor(Math.random() * 1000),
          length: dim.length,
          breadth: dim.breadth,
          height: dim.height,
          units: dim.units || 1,
          perUnitWeight: dim.perUnitWeight || 0,
          totalWeight: parseFloat(((dim.perUnitWeight || 0) * (dim.units || 1)).toFixed(2)),
        }))
      }));
      setSelectedSavedDim(dimId);
      toast.success(`Loaded dimensions: ${selectedDim.name}`);
    }
  };

  const handleDeleteDimensionClick = (id, e) => {
    e.stopPropagation();
    setDimToDelete(id);
    setShowDeleteConfirm(true);
  };

  const deleteSavedDimension = async () => {
    if (!dimToDelete) return;
    try {
      const group = savedDimensions.find(s => s.id.toString() === dimToDelete.toString());
      if (!group) {
        setShowDeleteConfirm(false);
        setDimToDelete(null);
        return;
      }
      const token = localStorage.getItem('token');
      if (token) {
        const deleteRequests = group.dimensions.map(d => {
          return axios.delete(`${import.meta.env.VITE_BASE_URL}/api/dynamic-price-manager/saved-dimensions/${d.id}`, {
            headers: { Authorization: `Bearer ${token}` }
          }).catch(() => null);
        });
        await Promise.all(deleteRequests);
        await fetchSavedDimensionsFromApi();
      } else {
        const updated = savedDimensions.filter(s => s.id.toString() !== dimToDelete.toString());
        setSavedDimensions(updated);
        localStorage.setItem('savedDimensions', JSON.stringify(updated));
      }
      if (selectedSavedDim === dimToDelete.toString()) {
        setSelectedSavedDim('');
        setFormState(prev => ({
          ...prev,
          dimensions: [{
            id: 1,
            length: '',
            breadth: '',
            height: '',
            units: 1,
            perUnitWeight: '',
            totalWeight: 0,
          }]
        }));
      }
      setShowDeleteConfirm(false);
      setDimToDelete(null);
      toast.success('Dimensions deleted successfully');
    } catch (err) {
      const updated = savedDimensions.filter(s => s.id.toString() !== dimToDelete.toString());
      setSavedDimensions(updated);
      localStorage.setItem('savedDimensions', JSON.stringify(updated));
      setShowDeleteConfirm(false);
      setDimToDelete(null);
      toast.success('Dimensions deleted successfully');
    }
  };

  const validateCOD = () => {
    const codValue = parseFloat(formState.codValue);
    const codSlabs = formState.codSlabs;
    if (!formState.toggles.collect_cod) return true;
    if (isNaN(codValue) || codValue <= 0) {
      toast.error("Please enter a valid COD amount");
      return false;
    }
    const maxAllowed = Math.max(...codSlabs.map(s => s.max));
    if (codValue > maxAllowed) {
      toast.error(`COD amount exceeds maximum allowed value of ₹${maxAllowed}`);
      return false;
    }
    const slab = codSlabs.find(s => codValue >= s.min && codValue <= s.max);
    if (!slab) {
      toast.error("No COD charge slab found for entered amount");
      return false;
    }
    return true;
  };

  const calculateDynamicPrice = () => {
    let totalUnitsCalc = 0;
    let totalVolumetricWeight = 0;
    let totalGrossWeight = 0;
    let totalVolumeCalc = 0;

    formState.dimensions.forEach(dim => {
      totalUnitsCalc += dim.units;
      const volumetricWeightPerUnit = (dim.length * dim.breadth * dim.height) / formState.volumetricFactor;
      totalVolumetricWeight += volumetricWeightPerUnit * dim.units;
      totalGrossWeight += dim.perUnitWeight * dim.units;
      totalVolumeCalc += dim.length * dim.breadth * dim.height * dim.units;
    });

    setTotalUnits(totalUnitsCalc);
    setVolumetricWeight(parseFloat(totalVolumetricWeight.toFixed(2)));
    setGrossWeight(parseFloat(totalGrossWeight.toFixed(2)));
    setTotalVolume(totalVolumeCalc);

    const chargeableWt = Math.max(totalGrossWeight, totalVolumetricWeight);
    setChargeableWeight(parseFloat(chargeableWt.toFixed(2)));

    let transport_amount = chargeableWt * formState.ratePerKg;
    let preTaxAmount = transport_amount;
    preTaxAmount = formState.toggles.express
      ? preTaxAmount + (preTaxAmount * formState.expressSurchargePercent / 100)
      : preTaxAmount;

    preTaxAmount = formState.toggles.challan_return ? preTaxAmount + formState.challan : preTaxAmount;

    if (formState.toggles.collect_cod && formState.codValue) {
      const cod = parseFloat(formState.codValue);
      const codSlab = formState.codSlabs.find(slab => cod >= slab.min && cod <= slab.max);
      const codCharge = codSlab ? codSlab.charge : 0;
      preTaxAmount += codCharge;

      setFormState((prevState) => ({
        ...prevState,
        charges: {
          ...prevState.charges,
          collect_cod: codCharge,
        },
      }));
    } else {
      setFormState((prevState) => ({
        ...prevState,
        charges: {
          ...prevState.charges,
          collect_cod: 0,
        },
      }));
    }

    const gst = preTaxAmount * (formState.gstRate / 100);
    const final = preTaxAmount + gst;

    setTransportAmount(parseFloat(transport_amount.toFixed(2)));
    setPreTaxAmount(parseFloat(preTaxAmount.toFixed(2)));
    setGstAmount(parseFloat(gst.toFixed(2)));
    setFinalPayable(parseFloat(final.toFixed(2)));
  };

  const updateDimension = (id, field, value) => {
    setFormState((prevState) => ({
      ...prevState,
      dimensions: prevState.dimensions.map(dim =>
        dim.id === id ? { ...dim, [field]: parseFloat(value) || 0 } : dim
      ),
    }));
  };

  const removeDimension = (id) => {
    if (formState.dimensions.length > 1) {
      setFormState((prevState) => ({
        ...prevState,
        dimensions: prevState.dimensions.filter(dim => dim.id !== id),
      }));
    }
  };

  const searchPlaces = async (term, type) => {
    const token = localStorage.getItem('token');
    try {
      const response = await fetch(`${import.meta.env.VITE_BASE_URL}/api/place-manager/search?term=${term}&type=${type}`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      });
      if (!response.ok) {
        throw new Error('Network response was not ok');
      }
      const data = await response.json();
      if (type === 'shipper') {
        setShipperResults(data.data);
      } else {
        setConsigneeResults(data.data);
      }
    } catch (error) {
      console.error('Error fetching places:', error);
    }
  };

  const handleShipperSearch = (e) => {
    const value = e.target.value;
    setShipperSearch(value);
    if (value.length >= 2) {
      searchPlaces(value, 'shipper');
      setShowShipperOptions(true);
    } else {
      setShipperResults([]);
      setShowShipperOptions(false);
    }
  };

  const handleConsigneeSearch = (e) => {
    const value = e.target.value;
    setConsigneeSearch(value);
    if (value.length >= 2) {
      searchPlaces(value, 'consignee');
      setShowConsigneeOptions(true);
    } else {
      setConsigneeResults([]);
      setShowConsigneeOptions(false);
    }
  };

  useEffect(() => {
    if (!dcClosingTime) return;
    const interval = setInterval(() => {
      const now = new Date();
      const [hours, minutes] = dcClosingTime.split(':').map(Number);
      const closingTime = new Date();
      closingTime.setHours(hours, minutes, 0, 0);
      if (now >= closingTime && pickupDateMin === todayStr) {
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        const tomorrowStr = tomorrow.toISOString().split('T')[0];
        setPickupDateMin(tomorrowStr);
        if (!formState.pickupDate || formState.pickupDate <= todayStr) {
          setField('pickupDate', tomorrowStr);
        }
        toast.warning("Pickup for today is closed. Earliest available date is tomorrow.");
      }
    }, 60000);
    return () => clearInterval(interval);
  }, [dcClosingTime, pickupDateMin, formState.pickupDate]);

  const handleShipperSearchInput = (e) => {
    const value = e.target.value;
    setShipperSearch(value);
    if (!value.trim()) {
      setPickupDateMin(todayStr);
      setDcClosingTime(null);
      setField('selectedShipper', null);
      return;
    }
    if (value.length >= 2) {
      searchPlaces(value, 'shipper');
      setShowShipperOptions(true);
    } else {
      setShipperResults([]);
      setShowShipperOptions(false);
    }
  };

  const handleShipperSelect = async (shipper) => {
    setShipperSearch(shipper.company_name);
    setField('selectedShipper', shipper.place_id);
    try {
      const token = localStorage.getItem('token');
      const res = await fetch(
        `${import.meta.env.VITE_BASE_URL}/api/dc-manager/closing-time/${shipper.place_id}`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      const data = await res.json();
      if (data.success && data.data.max_order_time) {
        setDcClosingTime(data.data.max_order_time);
        const now = new Date();
        const [hours, minutes] = data.data.max_order_time.split(':').map(Number);
        const closingTime = new Date();
        closingTime.setHours(hours, minutes, 0, 0);
        if (now >= closingTime) {
          const tomorrow = new Date();
          tomorrow.setDate(tomorrow.getDate() + 1);
          const tomorrowStr = tomorrow.toISOString().split('T')[0];
          setPickupDateMin(tomorrowStr);
          setField('pickupDate', tomorrowStr);
          toast.warning(
            `Pickup for today is closed. Earliest available date is tomorrow. (Cutoff: ${data.data.max_order_time} hrs)`
          );
        } else {
          setPickupDateMin(todayStr);
          if (!formState.pickupDate || formState.pickupDate < todayStr) {
            setField('pickupDate', todayStr);
          }
        }
      }
    } catch (err) {
      console.error('Error fetching closing time:', err);
      toast.error("Failed to fetch closing time");
    }
  };

  const normalizeTime = (timeStr) => {
    if (!timeStr) return null;
    if (/^\d{2}:\d{2}$/.test(timeStr)) return `${timeStr}:00`;
    return timeStr;
  };

  const handleSubmit = async () => {
    if (!validateCOD()) return;
    if (!formState.selectedShipper || !formState.selectedConsignee) {
      alert("Please select shipper and consignee");
      return;
    }
    if (formState.toggles.challan_return && challanFiles.length === 0) {
      toast.error('Please upload at least one Challan file before submitting');
      return;
    }
    if (formState.toggles.collect_cod && (!formState.codValue || isNaN(parseFloat(formState.codValue)) || parseFloat(formState.codValue) <= 0)) {
      toast.error('Please enter a valid COD amount');
      return;
    }
    const hasValidDimensions = formState.dimensions.some(
      (dim) => dim.length > 0 && dim.breadth > 0 && dim.height > 0
    );
    if (!hasValidDimensions) {
      alert("Please enter valid dimensions");
      return;
    }
    if (grossWeight <= 0) {
      alert("Please enter gross weight");
      return;
    }
    const token = localStorage.getItem("token");
    if (!token) {
      alert("Token not found");
      return;
    }
    const decodedToken = jwtDecode(token);
    const customerId =
      decodedToken.customer_id || decodedToken.id || decodedToken.user_id;
    if (!customerId) {
      alert("Customer ID not found in token");
      return;
    }
    const payload = {
      customer_id: customerId,
      pickup_place_id: formState.selectedShipper,
      drop_place_id: formState.selectedConsignee,
      schedule_date: formState.pickupDate,
      preferred_pickup_time: formState.pickupTime,
      consignee_closing_time: normalizeTime(formState.deliveryTime),
      pickup_note: formState.pickupNote,
      drop_note: formState.dropNote,
      commodity: formState.commodity,
      price_module_type: "dynamic",
      express_delivery: formState.toggles.express,
      express_charges: formState.toggles.express
        ? transport_amount * (formState.expressSurchargePercent / 100)
        : 0,
      challan_return: formState.toggles.challan_return,
      challan_charges: formState.toggles.challan_return ? formState.challan : 0,
      challan_return_status: formState.toggles.challan_return ? "pending" : null,
      cod_collection: formState.toggles.collect_cod,
      cod_amount: formState.toggles.collect_cod ? formState.codValue : 0,
      cod_status: formState.toggles.collect_cod ? "pending" : null,
      cod_charges: formState.toggles.collect_cod
        ? formState.charges.collect_cod
        : 0,
      dimensions: formState.dimensions.map((dim) => {
        const volumetricWeightPerUnit =
          (dim.length * dim.breadth * dim.height) / formState.volumetricFactor;
        return {
          id: dim.id,
          length: dim.length,
          breadth: dim.breadth,
          height: dim.height,
          units: dim.units,
          perUnitWeight: dim.perUnitWeight,
          volumetricWeightPerUnit: parseFloat(
            volumetricWeightPerUnit.toFixed(2)
          ),
          totalVolume: dim.length * dim.breadth * dim.height * dim.units,
          totalWeight: parseFloat((dim.perUnitWeight * dim.units).toFixed(2)),
        };
      }),
      total_units: totalUnits,
      total_gross_weight: grossWeight,
      total_vol_weight: volumetricWeight,
      total_volume: totalVolume,
      chargeable_weight: chargeableWeight,
      transportation_charges: transport_amount,
      applied_coupon: couponApplied ? couponApplied.coupon_code : null,
      coupon_discount: couponDiscount,
      pre_tax_amount: preTaxAmount,
      gst_percentage: formState.gstRate,
      gst_amount: gstAmount,
      final_payable: finalPayable,
    };
    console.log("Payload to submit:", payload);
    const isConfirmed = window.confirm(
      `Final payable amount is ₹${finalPayable}. Do you want to proceed?`
    );
    if (!isConfirmed) return;
    const formData = new FormData();
    Object.keys(payload).forEach(key => {
      if (key === 'dimensions' || key === 'commodity') {
        formData.append(key, JSON.stringify(payload[key]));
      } else if (payload[key] !== null && payload[key] !== undefined) {
        formData.append(key, payload[key]);
      }
    });
    if (challanFiles && challanFiles.length > 0) {
      challanFiles.forEach((file) => {
        formData.append('challan_files', file);
      });
    }
    try {
      const response = await axios.post(
        `${import.meta.env.VITE_BASE_URL}/api/order-manager`,
        formData,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'multipart/form-data',
          },
        }
      );
      toast.success("Order submitted successfully!");
      if (onSuccess && response.data?.data?.order_id) {
        onSuccess(response.data.data.order_id);
      }
    } catch (error) {
      console.error("Error submitting order:", error);
      if (error.response?.data?.message) {
        toast.error(error.response.data.message);
      } else {
        toast.error("Failed to submit order. Please try again.");
      }
    }
  };

  const handleApplyCoupon = async () => {
    setCouponValidationError(null);
    
    if (couponApplied) {
      toast.info("A coupon is already applied");
      return;
    }
    
    if (couponCode.trim() === '') {
      toast.error("Please enter a coupon code");
      return;
    }

    // Get customer ID from token
    let customerId = null;
    try {
      const token = localStorage.getItem('token');
      if (token) {
        const decoded = jwtDecode(token);
        customerId = decoded.customer_id || decoded.id || decoded.user_id;
      }
    } catch (err) {
      console.error('Error decoding token:', err);
    }

    if (!customerId) {
      toast.error("Customer ID not found. Please refresh the page.");
      return;
    }

    // Calculate pre-tax amount for validation
    let preCheckPreTaxAmount = transport_amount;
    if (formState.toggles.express) {
      preCheckPreTaxAmount += transport_amount * (formState.expressSurchargePercent / 100);
    }
    if (formState.toggles.challan_return) {
      preCheckPreTaxAmount += formState.challan;
    }
    if (formState.toggles.collect_cod) {
      preCheckPreTaxAmount += formState.charges.collect_cod;
    }

    setIsValidatingCoupon(true);

    try {
      const token = localStorage.getItem('token');
      // Call RTK API to validate coupon with backend constraints
      const response = await fetch(
        `${import.meta.env.VITE_BASE_URL}/api/discount-coupon/validate/${couponCode.trim()}?customer_id=${customerId}&order_amount=${preCheckPreTaxAmount}`,
        {
          method: 'GET',
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        }
      );

      const data = await response.json();

      if (!response.ok) {
        const errorMsg = data?.message || 'Invalid coupon';
        setCouponValidationError(errorMsg);
        toast.error(errorMsg);
        setIsValidatingCoupon(false);
        return;
      }

      // Coupon validation passed - find the coupon object and apply it
      const coupon = data.data || data;
      
      // Use the existing logic to find coupon by code
      const foundCoupon = activeCoupons.find(c => c.coupon_code === couponCode);
      if (foundCoupon) {
        setCouponApplied(foundCoupon);
        setCouponValidationError(null);
        toast.success(`Coupon "${couponCode}" applied successfully!`);
      } else {
        // Fallback: use the coupon data from API response
        setCouponApplied(coupon);
        setCouponValidationError(null);
        toast.success(`Coupon "${couponCode}" applied successfully!`);
      }

    } catch (err) {
      const errorMsg = err.message || 'Failed to validate coupon';
      setCouponValidationError(errorMsg);
      toast.error(errorMsg);
      console.error('Coupon validation error:', err);
    } finally {
      setIsValidatingCoupon(false);
    }
  };

  const handleRemoveCoupon = () => {
    setCouponApplied(null);
    setCouponCode('');
    setCouponDiscount(0);
  };

  useEffect(() => {
    const fetchActiveDynamicPrice = async () => {
      try {
        const token = localStorage.getItem('token');
        axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;
        const res = await axios.get(`${import.meta.env.VITE_BASE_URL}/api/dynamic-price-manager/active`);
        const data = res.data?.data;
        if (!data) return;
        setFormState(prev => {
          const newState = {
            ...prev,
            ratePerKg: toNumber(data.base_fare_per_kg),
            volumetricFactor: toNumber(data.volumetric_factor),
            challan: toNumber(data.chalaan_return_charges),
            expressSurchargePercent: toNumber(data.express_delivery_surcharge_percentage),
            gstRate: toNumber(data.gst_percentage),
            codSlabs: Array.isArray(data.cod_ranges)
              ? data.cod_ranges.map(r => ({
                min: r.range?.[0] ?? 0,
                max: r.range?.[1] ?? 0,
                charge: toNumber(r.charge)
              }))
              : [],
          };
          return newState;
        });
      } catch (err) {
        console.error('Failed to fetch active dynamic price', err);
      }
    };
    fetchActiveDynamicPrice();
  }, []);

  useEffect(() => {
    const fetchDeliveryTimeFromBackend = async () => {
      const response = await new Promise(resolve => {
        setTimeout(() => {
          resolve({ closingTime: "11:30" });
        }, 1000);
      });
      if (response.closingTime) {
        setField('deliveryTime', response.closingTime);
      }
    };
    if (formState.selectedConsignee) {
      fetchDeliveryTimeFromBackend();
    }
  }, [formState.selectedConsignee]);

  useEffect(() => {
    calculateDynamicPrice();
  }, [
    formState.dimensions,
    formState.ratePerKg,
    formState.toggles,
    formState.volumetricFactor,
    formState.codValue,
    formState.expressSurchargePercent,
    formState.challan,
    formState.gstRate,
    formState.codSlabs
  ]);

  useEffect(() => {
    let preTax = transport_amount;
    if (formState.toggles.express) {
      preTax += transport_amount * (formState.expressSurchargePercent / 100);
    }
    if (formState.toggles.challan_return) {
      preTax += formState.challan;
    }
    if (formState.toggles.collect_cod) {
      preTax += formState.charges.collect_cod;
    }
    let calculatedDeduction = 0;
    if (couponApplied) {
      const discountPercent = parseFloat(couponApplied.discount_value) / 100;
      const maxCap = parseFloat(couponApplied.max_discount_cap);
      let discount = preTax * discountPercent;
      if (discount > maxCap) {
        discount = maxCap;
      }
      calculatedDeduction = Math.min(discount, preTax);
    }
    setCouponDiscount(calculatedDeduction);
    let preTaxAfterCoupon = preTax - calculatedDeduction;
    const gst = preTaxAfterCoupon * (formState.gstRate / 100);
    setPreTaxAmount(parseFloat(preTaxAfterCoupon.toFixed(2)));
    setGstAmount(parseFloat(gst.toFixed(2)));
    setFinalPayable(parseFloat((preTaxAfterCoupon + gst).toFixed(2)));
  }, [
    transport_amount,
    formState.toggles,
    couponApplied,
    formState.expressSurchargePercent,
    formState.challan,
    formState.charges.collect_cod,
    formState.gstRate
  ]);

  const Modal = ({ isOpen, onClose, title, children, onConfirm, confirmText = 'Save', confirmVariant = 'bg-blue-500 hover:bg-blue-600' }) => {
    if (!isOpen) return null;
    return (
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
        <div className="bg-white rounded-lg w-full max-w-md max-h-[90vh] overflow-y-auto">
          <div className="p-4 border-b">
            <h3 className="text-lg font-medium">{title}</h3>
          </div>
          <div className="p-4">
            {children}
          </div>
          <div className="p-4 border-t flex justify-end gap-2">
            <button
              onClick={onClose}
              className="px-4 py-2 border border-gray-300 rounded hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              onClick={onConfirm}
              className={`px-4 py-2 text-white rounded ${confirmVariant}`}
            >
              {confirmText}
            </button>
          </div>
        </div>
      </div>
    );
  };

  useEffect(() => {
    try {
      const token = localStorage.getItem('token');
      if (token) {
        const decoded = jwtDecode(token);
        // Just for storing customerId if needed for API calls
        window.customerId = decoded.customer_id || decoded.id || decoded.user_id;
      }
    } catch (err) {
      console.error('Error decoding token:', err);
    }
  }, []);

  return (
    <div className="w-full max-w-3xl bg-white p-1 rounded-lg relative">
      <div className="text-center mb-6 flex items-center justify-between">
        {/* <h2 className="text-xl font-bold text-left">Logistics Order Form</h2> */}
      </div>

      <div className="mb-4">
        <label className="block mb-2 text-sm font-medium">Commodity</label>
        <InputSuggestion
          passOrderMode={'dynamic-price'}
          value={formState.commodity}
          onChange={(newCommodity) => setField('commodity', newCommodity)}
        />
      </div>

      <div className="mb-4 relative">
        <label className="block text-sm font-medium mb-2">Select Pre-Registered Shipper:</label>
        <input
          type="text"
          value={shipperSearch}
          onChange={handleShipperSearchInput}
          onFocus={() => shipperSearch.length >= 2 && setShowShipperOptions(true)}
          onBlur={() => setTimeout(() => setShowShipperOptions(false), 150)}
          placeholder="Search Shipper"
          className="w-full p-2 border border-gray-300 rounded"
          autoComplete="off"
        />
        {showShipperOptions && shipperSearch && (
          <div className="border border-gray-300 rounded bg-white shadow max-h-40 overflow-y-auto absolute z-10 w-full">
            {shipperResults.length === 0 ? (
              <div className="p-2 text-gray-500">No shippers found</div>
            ) : (
              shipperResults.map(s => (
                <div
                  key={s.id}
                  className="p-2 hover:bg-blue-100 cursor-pointer"
                  onMouseDown={() => handleShipperSelect(s)}
                >
                  <div className="font-semibold">
                    {s.company_name} <span className="text-xs text-gray-500">({s.place_id})</span>
                  </div>
                  <div className="text-xs text-gray-600">
                    {s.contact_person_name} | {s.contact_person_mobile}
                  </div>
                </div>
              ))
            )}
          </div>
        )}
      </div>

      <div className="mb-4">
        <label htmlFor="pickupDate" className="block text-sm font-medium mb-2">Preferred Pickup Date</label>
        <input
          id="pickupDate"
          type="date"
          value={formState.pickupDate}
          onChange={e => setField('pickupDate', e.target.value)}
          className="w-full p-2 border border-gray-300 rounded"
          min={pickupDateMin}
        />
        {dcClosingTime && (
          <p className="text-xs text-gray-500 mt-1">
            DC closing time: {dcClosingTime} hrs
          </p>
        )}
      </div>

      <div className="mb-4">
        <label htmlFor="pickupTime" className="block text-sm font-medium mb-2">Preferred Pickup Time</label>
        <select
          id="pickupTime"
          className="w-full p-2 border border-gray-300 rounded"
          value={formState.pickupTime}
          onChange={e => setField('pickupTime', e.target.value)}
        >
          <option value="">Choose a Time</option>
          {timeStramp.map((time) => (
            <option value={time} key={time}>{time}</option>
          ))}
        </select>
      </div>

      <div className="mb-4">
        <label className="block text-sm font-medium mb-2">Pickup Note:</label>
        <textarea
          value={formState.pickupNote}
          onChange={(e) => setField('pickupNote', e.target.value)}
          placeholder="Enter any pickup instructions..."
          className="w-full p-2 border border-gray-300 rounded h-20"
        />
      </div>

      <div className="mb-4 relative">
        <label className="block text-sm font-medium mb-2">Select Pre-Registered Consignee:</label>
        <input
          type="text"
          value={consigneeSearch}
          onChange={handleConsigneeSearch}
          onFocus={() => consigneeSearch.length >= 2 && setShowConsigneeOptions(true)}
          onBlur={() => setTimeout(() => setShowConsigneeOptions(false), 150)}
          placeholder="Search Consignee"
          className="w-full p-2 border border-gray-300 rounded"
          autoComplete="off"
        />
        {showConsigneeOptions && consigneeSearch && (
          <div className="border border-gray-300 rounded bg-white shadow max-h-40 overflow-y-auto absolute z-10 w-full">
            {consigneeResults.length === 0 ? (
              <div className="p-2 text-gray-500">No consignees found</div>
            ) : (
              consigneeResults.map(c => (
                <div
                  key={c.id}
                  className="p-2 hover:bg-blue-100 cursor-pointer"
                  onMouseDown={() => {
                    setConsigneeSearch(c.company_name);
                    setField('selectedConsignee', c.place_id);
                  }}
                >
                  <div className="font-semibold">{c.company_name} <span className="text-xs text-gray-500">({c.place_id})</span></div>
                  <div className="text-xs text-gray-600">
                    {c.contact_person_name} | {c.contact_person_mobile}
                  </div>
                </div>
              ))
            )}
          </div>
        )}
      </div>

      <div className="mb-4">
        <label className="block text-sm font-medium mb-2">Consignee Closing Time:</label>
        <input
          type="time"
          value={formState.deliveryTime}
          onChange={(e) => setField('deliveryTime', e.target.value)}
          className="w-full p-2 border border-gray-300 rounded"
        />
      </div>

      <div className="mb-4">
        <label className="block text-sm font-medium mb-2">Drop Note:</label>
        <textarea
          value={formState.dropNote}
          onChange={(e) => setField('dropNote', e.target.value)}
          placeholder="Enter any delivery instructions..."
          className="w-full p-2 border border-gray-300 rounded h-20"
        />
      </div>

      <div className="flex items-center gap-6 flex-wrap mt-9 mb-9 mx-2">
        <div className="flex items-center gap-2">
          <label className="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              checked={formState.toggles.express}
              onChange={handleToggle("express")}
              className="sr-only peer"
            />
            <div className="w-10 h-5 bg-gray-300 rounded-full peer peer-checked:bg-blue-600 transition duration-300"></div>
            <div className="absolute left-1 top-0.5 w-4 h-4 bg-white rounded-full transition-transform duration-300 peer-checked:translate-x-5"></div>
          </label>
          <span className="text-gray-700 text-sm">Express Delivery</span>
        </div>

        <div className="flex items-center gap-2">
          <label className="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              checked={formState.toggles.challan_return}
              onChange={handleToggle("challan_return")}
              className="sr-only peer"
            />
            <div className="w-10 h-5 bg-gray-300 rounded-full peer peer-checked:bg-blue-600 transition duration-300"></div>
            <div className="absolute left-1 top-0.5 w-4 h-4 bg-white rounded-full transition-transform duration-300 peer-checked:translate-x-5"></div>
          </label>
          <span className="text-gray-700 text-sm">Challan Return</span>
        </div>

        <div className="flex items-center gap-2">
          <label className="relative inline-flex items-center cursor-pointer">
            <input
              id="collect_cod"
              type="checkbox"
              checked={formState.toggles.collect_cod}
              onChange={handleToggle("collect_cod")}
              className="sr-only peer"
            />
            <div className="w-10 h-5 bg-gray-300 rounded-full peer peer-checked:bg-blue-600 transition duration-300"></div>
            <div className="absolute left-1 top-0.5 w-4 h-4 bg-white rounded-full transition-transform duration-300 peer-checked:translate-x-5"></div>
          </label>
          <label htmlFor="collect_cod" className="text-gray-700 text-sm">Collect COD</label>
        </div>
      </div>

      {formState.toggles.challan_return && (
        <div className="mb-4">
          <label className="block text-sm font-medium mb-2">Challan Documents (Images & PDFs)</label>
          <input
            type="file"
            accept="image/*, .pdf"
            multiple
            className="block w-full text-sm text-gray-700 border border-gray-300 rounded-md cursor-pointer file:mr-2 file:py-1 file:px-2 file:rounded-md file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100"
            onChange={handleChallanUpload}
          />
          {challanFiles.length > 0 && (
            <div className="mt-2 text-sm text-gray-600">
              Selected files:
              <ul className="list-disc list-inside mt-1">
                {challanFiles.map((file, index) => (
                  <li key={index} className="flex items-center justify-between w-full">
                    <span className="text-blue-600">{file.name}</span>
                    <button
                      onClick={() => handleRemoveChallanFile(index)}
                      className="text-red-500 hover:text-red-700 text-lg font-bold"
                    >
                      ×
                    </button>
                  </li>
                ))}
              </ul>
            </div>
          )}
        </div>
      )}

      {formState.toggles.collect_cod && (
        <div className="space-y-2">
          <input
            type="number"
            value={formState.codValue}
            onChange={(e) => setField('codValue', e.target.value)}
            placeholder="Enter COD amount"
            className="w-50 px-3 py-1 my-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-400"
          />

          {(() => {
            const codValue = parseFloat(formState.codValue);
            const codSlabs = formState.codSlabs || [];
            const maxAllowed = Math.max(...codSlabs.map(s => s.max || 0));

            if (!formState.codValue) return null;

            if (isNaN(codValue) || codValue <= 0) {
              return <div className="text-sm text-red-600">Invalid COD amount</div>;
            }

            if (codValue > maxAllowed) {
              return (
                <div className="text-sm text-red-600">
                  COD amount exceeds maximum allowed value (₹{maxAllowed})
                </div>
              );
            }

            const slab = codSlabs.find(s => codValue >= s.min && codValue <= s.max);
            if (!slab) {
              return (
                <div className="text-sm text-red-600">
                  No applicable COD charge slab found for entered amount
                </div>
              );
            }

            return (
              <div className="text-sm text-blue-600">
                COD Charge Slab: ₹{slab.min} - ₹{slab.max} → ₹{slab.charge}
              </div>
            );
          })()}
        </div>
      )}

      <div className="mb-6">
        <div className="flex flex-col md:flex-row md:justify-between md:items-center mb-4 gap-3">
          <h3 className="text-lg font-medium">Dimensions</h3>
          <div className="flex flex-col sm:flex-row gap-3 w-full md:w-auto">
            <div className="relative flex-grow">
              <div className="relative">
                <div 
                  className="w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 appearance-none pr-8 cursor-pointer bg-white"
                  onClick={() => document.getElementById('dimensionsDropdown').classList.toggle('hidden')}
                >
                  {selectedSavedDim 
                    ? (() => {
                        const selectedDim = savedDimensions.find(d => d.id === selectedSavedDim);
                        const firstDim = selectedDim?.dimensions[0];
                        const dimText = firstDim
                          ? `${firstDim.length}×${firstDim.breadth}×${firstDim.height} cm`
                          : '';
                        return selectedDim ? `${selectedDim.name} - ${dimText}` : 'Select saved dimensions';
                      })()
                    : 'Select saved dimensions'}
                </div>
                <div className="absolute inset-y-0 right-0 flex items-center pr-2 pointer-events-none">
                  <svg className="h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                  </svg>
                </div>
                <div id="dimensionsDropdown" className="hidden absolute right-0 left-0 z-10 mt-1 bg-white border border-gray-200 rounded-md shadow-lg max-h-60 overflow-auto">
                  {savedDimensions.map((dim) => {
                    const firstDim = dim.dimensions[0];
                    const dimText = firstDim
                      ? `${firstDim.length}×${firstDim.breadth}×${firstDim.height} cm`
                      : '';
                    return (
                      <div 
                        key={dim.id} 
                        className="px-4 py-2 hover:bg-gray-100 flex justify-between items-center cursor-pointer"
                        onClick={() => {
                          setSelectedSavedDim(dim.id);
                          document.getElementById('dimensionsDropdown').classList.add('hidden');
                          handleDimensionSelect({ target: { value: dim.id } });
                        }}
                      >
                        <span>{dim.name} - {dimText}</span>
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            handleDeleteDimensionClick(dim.id, e);
                          }}
                          className="text-red-500 hover:text-red-700 ml-2"
                          title="Delete this dimension"
                        >
                          <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                          </svg>
                        </button>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
            <button
              type="button"
              onClick={handleSaveDimensionsClick}
              className="px-4 py-2 bg-green-500 text-white rounded hover:bg-green-600 whitespace-nowrap"
            >
              Save Dimensions
            </button>
          </div>
        </div>
        {formState.dimensions.map((dim, index) => (
          <div key={dim.id} className="border border-gray-300 rounded p-4 mb-4">
            <div className="flex justify-between items-center mb-3">
              <h4 className="font-medium text-blue-600">Dimension {index + 1}</h4>
              {formState.dimensions.length > 1 && (
                <button
                  onClick={() => removeDimension(dim.id)}
                  className="text-red-500 hover:text-red-700 text-lg font-bold"
                >
                  ×
                </button>
              )}
            </div>

            <div className="grid grid-cols-2 gap-4 mb-3">
              <div>
                <label className="block text-sm text-blue-600 mb-1">Length (cm)</label>
                <input
                  type="number"
                  value={dim.length || ''}
                  onChange={(e) => updateDimension(dim.id, 'length', e.target.value)}
                  className="w-full p-2 border border-gray-300 rounded focus:outline-none focus:ring-1 focus:ring-blue-500"
                  min="0"
                  step="0.1"
                />
              </div>
              <div>
                <label className="block text-sm text-blue-600 mb-1">Breadth (cm)</label>
                <input
                  type="number"
                  value={dim.breadth || ''}
                  onChange={(e) => updateDimension(dim.id, 'breadth', e.target.value)}
                  className="w-full p-2 border border-gray-300 rounded focus:outline-none focus:ring-1 focus:ring-blue-500"
                  min="0"
                  step="0.1"
                />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm text-blue-600 mb-1">Height (cm)</label>
                <input
                  type="number"
                  value={dim.height || ''}
                  onChange={(e) => updateDimension(dim.id, 'height', e.target.value)}
                  className="w-full p-2 border border-gray-300 rounded focus:outline-none focus:ring-1 focus:ring-blue-500"
                  min="0"
                  step="0.1"
                />
              </div>
              <div>
                <label className="block text-sm text-blue-600 mb-1">No. of Units</label>
                <input
                  type="number"
                  value={dim.units || ''}
                  onChange={(e) => updateDimension(dim.id, 'units', e.target.value)}
                  className="w-full p-2 border border-gray-300 rounded focus:outline-none focus:ring-1 focus:ring-blue-500"
                  min="1"
                />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4 mt-3">
              <div>
                <label className="block text-sm text-blue-600 mb-1">Per Unit Weight (kg)</label>
                <input
                  type="number"
                  value={dim.perUnitWeight || ''}
                  onChange={(e) => updateDimension(dim.id, 'perUnitWeight', e.target.value)}
                  className="w-full p-2 border border-gray-300 rounded focus:outline-none focus:ring-1 focus:ring-blue-500"
                  min="0"
                  step="0.1"
                  placeholder="0.0"
                />
              </div>
              <div>
                <label className="block text-sm text-blue-600 mb-1">Total Weight (kg)</label>
                <input
                  type="number"
                  value={(dim.perUnitWeight * dim.units).toFixed(2)}
                  readOnly
                  className="w-full p-2 border border-gray-300 rounded bg-gray-50 text-gray-700"
                />
              </div>
            </div>

            <div className="mt-3 p-2 bg-blue-50 rounded">
              <div className="text-sm text-blue-700">
                <span className="font-medium">Volumetric Weight:</span> {((dim.length * dim.breadth * dim.height) / formState.volumetricFactor).toFixed(2)} kg
              </div>
              <div className="text-sm text-blue-700">
                <span className="font-medium">Total Volume:</span> {(dim.length * dim.breadth * dim.height * dim.units).toLocaleString()} cm³
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="mb-6 bg-gray-50 p-4 rounded-lg">
        <h4 className="font-semibold mb-3 text-gray-800">Weight & Price Summary</h4>
        <div className="space-y-2">
          <div className="flex justify-between">
            <span>Total Units:</span>
            <span className="font-semibold">{totalUnits}</span>
          </div>
          <div className="flex justify-between">
            <span>Total Gross Weight:</span>
            <span className="font-semibold">{grossWeight} kg</span>
          </div>
          <div className="flex justify-between">
            <span>Total Volumetric Weight:</span>
            <span className="font-semibold">{volumetricWeight} kg</span>
          </div>
          <div className="flex justify-between">
            <span>Total Volume:</span>
            <span className="font-semibold">{totalVolume} cm³</span>
          </div>
          <div className="flex justify-between text-lg font-bold pt-2 border-t border-green-300 text-green-800">
            <h4>Chargeable Weight:</h4>
            <span className="font-semibold mb-3 text-green-800">{chargeableWeight} kg</span>
          </div>
        </div>
      </div>

      <div className="mb-6 bg-white p-4 rounded-lg border border-gray-200">
        <h4 className="font-semibold mb-3 text-gray-800 text-lg">Price Calculation</h4>
        <div className="space-y-3">
          <div className="flex justify-between text-gray-700">
            <span>Transport Charges</span>
            <span className="font-medium">₹{transport_amount.toFixed(2)}</span>
          </div>
          
          {formState.toggles.express && (
            <div className="flex justify-between text-gray-700">
              <span>Express Surcharge ({formState.expressSurchargePercent}%)</span>
              <span className="font-medium">
                ₹{(transport_amount * formState.expressSurchargePercent / 100).toFixed(2)}
              </span>
            </div>
          )}
          
          {formState.toggles.challan_return && (
            <div className="flex justify-between text-gray-700">
              <span>Challan Return</span>
              <span className="font-medium">₹{(formState.challan || 0).toFixed(2)}</span>
            </div>
          )}
          
          {formState.toggles.collect_cod && (
            <div className="flex justify-between text-gray-700">
              <span>COD Collect</span>
              <span className="font-medium">
                ₹{(formState.charges?.collect_cod || 0).toFixed(2)}
              </span>
            </div>
          )}
          
          <div className="flex justify-between pt-2 border-t border-gray-200">
            <span className="font-medium">Sub Total</span>
            <span className="font-medium">₹{preTaxAmount.toFixed(2)}</span>
          </div>
          
          {couponApplied ? (
            <div className="flex flex-col bg-green-50 p-2 rounded">
              <div className="flex justify-between text-green-700">
                <span>Coupon Applied ({couponApplied.coupon_code})</span>
                <span className="font-medium">-₹{couponDiscount.toFixed(2)}</span>
              </div>
              <div className="flex justify-between font-medium mt-1">
                <span>Discounted Amount</span>
                <span>₹{(preTaxAmount - couponDiscount).toFixed(2)}</span>
              </div>
            </div>
          ) : (
            <button
              type="button"
              onClick={() => setField('showCouponField', !formState.showCouponField)}
              className="w-full text-blue-600 text-sm hover:underline py-1 text-center"
            >
              {formState.showCouponField ? 'Hide Coupon Code' : 'Have a Coupon Code?'}
            </button>
          )}
          
          {formState.showCouponField && !couponApplied && (
            <div className="mt-2 flex flex-col sm:flex-row gap-2">
              <input
                type="text"
                value={couponCode}
                onChange={e => {
                  setCouponCode(e.target.value);
                  setCouponValidationError(null);
                }}
                placeholder={isValidatingCoupon ? "Validating..." : "Enter coupon code"}
                className="flex-1 p-2 border border-gray-300 rounded text-sm disabled:bg-gray-100 w-full"
                disabled={isValidatingCoupon || isLoadingCoupons}
                onKeyDown={(e) => e.key === 'Enter' && !isValidatingCoupon && handleApplyCoupon()}
              />
              <button
                onClick={handleApplyCoupon}
                className="px-4 py-2 bg-blue-500 text-white text-sm rounded hover:bg-blue-600 disabled:bg-gray-400 whitespace-nowrap"
                type="button"
                disabled={isValidatingCoupon || !couponCode.trim()}
              >
                {isValidatingCoupon ? 'Validating...' : 'Apply'}
              </button>
            </div>
          )}
          
          {couponValidationError && (
            <p className="text-xs text-red-500 mt-1">{couponValidationError}</p>
          )}
          
          <div className="flex justify-between text-gray-700 pt-2 border-t border-gray-200">
            <span>GST ({(formState.gstRate || 0).toFixed(0)}%)</span>
            <span className="font-medium">
              {new Intl.NumberFormat('en-IN', {
                style: 'currency',
                currency: 'INR',
              }).format(gstAmount)}
            </span>
          </div>
          
          <div className="flex justify-between pt-3 mt-2 border-t-2 border-gray-300 font-bold text-lg">
            <span>Final Payable</span>
            <span className="text-blue-700">
              {new Intl.NumberFormat('en-IN', {
                style: 'currency',
                currency: 'INR',
              }).format(finalPayable).replace('.00', '')}
            </span>
          </div>
          
          {couponError && formState.showCouponField && (
            <p className="text-xs text-red-500 mt-1">{couponError}</p>
          )}
        </div>
      </div>

      <div className="flex flex-col gap-4">
        <div className="flex gap-4">
          <button
            onClick={handleSubmit}
            className="flex-1 bg-blue-500 hover:bg-blue-600 text-white py-2 rounded"
          >
            Submit Order
          </button>
          <button
            onClick={() => window.location.reload()}
            className="flex-1 bg-gray-500 hover:bg-gray-600 text-white py-2 rounded"
            type="button"
          >
            Reset
          </button>
          <button
            onClick={() => alert('Bulk order feature coming soon!')}
            className="flex-1 bg-yellow-500 hover:bg-yellow-600 text-white py-2 rounded"
            type="button"
          >
            Bulk Order
          </button>
        </div>
        <div className="text-center text-sm text-gray-600">
          Checkout our:{' '}
          <a 
            href="/refund-policy" 
            target="_blank" 
            rel="noopener noreferrer"
            className="text-blue-500 hover:underline"
          >
            Refund Policy
          </a>
        </div>
      </div>

      {showSaveDimModal && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-lg flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg w-full max-w-md">
            <div className="p-4 border-b">
              <h3 className="text-lg font-medium">Save Dimensions</h3>
            </div>
            <div className="p-4">
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Name for these dimensions:
                </label>
                <input
                  type="text"
                  value={newDimName}
                  onChange={(e) => setNewDimName(e.target.value)}
                  className="w-full p-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="e.g., Small Package, Large Box"
                  autoFocus
                />
              </div>
            </div>
            <div className="p-4 border-t flex justify-end gap-2">
              <button
                onClick={() => setShowSaveDimModal(false)}
                className="px-4 py-2 border border-gray-300 rounded hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={saveCurrentDimensions}
                className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
              >
                Save
              </button>
            </div>
          </div>
        </div>
      )}

      {showDeleteConfirm && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg w-full max-w-md">
            <div className="p-4 border-b">
              <h3 className="text-lg font-medium">Delete Saved Dimensions</h3>
            </div>
            <div className="p-4">
              <p className="text-gray-700">Are you sure you want to delete these saved dimensions? This action cannot be undone.</p>
            </div>
            <div className="p-4 border-t flex justify-end gap-2">
              <button
                onClick={() => {
                  setShowDeleteConfirm(false);
                  setDimToDelete(null);
                }}
                className="px-4 py-2 border border-gray-300 rounded hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={deleteSavedDimension}
                className="px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default BookDynamicPrice;
