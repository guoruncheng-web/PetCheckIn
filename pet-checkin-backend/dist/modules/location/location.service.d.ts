export interface LocationInfo {
    cityCode: string;
    cityName: string;
    province: string;
    country: string;
}
export declare class LocationService {
    private readonly logger;
    getCityByIp(ip: string): Promise<LocationInfo | null>;
    getClientIp(request: any): string;
    private getDefaultLocation;
    private getCityCode;
}
