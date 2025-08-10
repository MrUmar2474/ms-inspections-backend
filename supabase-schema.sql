-- MS Inspections Database Schema for Supabase
-- Run this in your Supabase SQL Editor

-- Create custom types
CREATE TYPE user_role AS ENUM ('ADMIN', 'SURVEYOR', 'VIEWER');
CREATE TYPE survey_status AS ENUM ('PENDING', 'SURVEY_DONE', 'REPORT_PENDING', 'COMPLETED');

-- Create users table
CREATE TABLE users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    role user_role DEFAULT 'VIEWER',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create surveys table
CREATE TABLE surveys (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registration_number VARCHAR(50) UNIQUE NOT NULL,
    make VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    year INTEGER NOT NULL,
    vin VARCHAR(17) UNIQUE NOT NULL,
    color VARCHAR(50) NOT NULL,
    mileage INTEGER,
    owner_name VARCHAR(255) NOT NULL,
    owner_phone VARCHAR(20) NOT NULL,
    owner_email VARCHAR(255),
    inspection_date TIMESTAMP WITH TIME ZONE NOT NULL,
    location VARCHAR(255) NOT NULL,
    status survey_status DEFAULT 'PENDING',
    notes TEXT,
    damage_photos TEXT DEFAULT '[]', -- JSON string array
    surveyor_id UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create reports table
CREATE TABLE reports (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    survey_id UUID UNIQUE REFERENCES surveys(id) ON DELETE CASCADE,
    summary TEXT NOT NULL,
    findings TEXT NOT NULL,
    recommendations TEXT,
    estimated_cost DECIMAL(10,2),
    generated_by UUID REFERENCES users(id),
    file_path VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_surveys_status ON surveys(status);
CREATE INDEX idx_surveys_surveyor_id ON surveys(surveyor_id);
CREATE INDEX idx_surveys_inspection_date ON surveys(inspection_date);
CREATE INDEX idx_surveys_registration_number ON surveys(registration_number);
CREATE INDEX idx_reports_survey_id ON reports(survey_id);
CREATE INDEX idx_users_email ON users(email);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_surveys_updated_at BEFORE UPDATE ON surveys
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reports_updated_at BEFORE UPDATE ON reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert sample data
INSERT INTO users (email, password, name, role) VALUES
('admin@msinspections.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/VcSAg/9PS', 'System Administrator', 'ADMIN'),
('surveyor1@msinspections.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/VcSAg/9PS', 'John Smith', 'SURVEYOR'),
('surveyor2@msinspections.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/VcSAg/9PS', 'Sarah Johnson', 'SURVEYOR');

-- Insert sample surveys
INSERT INTO surveys (
    registration_number, make, model, year, vin, color, mileage,
    owner_name, owner_phone, owner_email, inspection_date, location,
    status, notes, surveyor_id
) VALUES
('ABC123', 'Toyota', 'Camry', 2020, '1HGBH41JXMN109186', 'Silver', 45000,
 'John Doe', '+1-555-0101', 'john.doe@email.com', '2024-01-15 10:00:00+00',
 'Downtown Service Center', 'PENDING', 'Initial inspection scheduled',
 (SELECT id FROM users WHERE email = 'surveyor1@msinspections.com')),

('XYZ789', 'Honda', 'Civic', 2019, '2HGFC2F59KH123456', 'Blue', 32000,
 'Jane Smith', '+1-555-0102', 'jane.smith@email.com', '2024-01-16 14:00:00+00',
 'Westside Auto Center', 'SURVEY_DONE', 'Survey completed, minor scratches found',
 (SELECT id FROM users WHERE email = 'surveyor2@msinspections.com')),

('DEF456', 'Ford', 'F-150', 2021, '1FTFW1ET5DFC12345', 'Red', 28000,
 'Bob Wilson', '+1-555-0103', 'bob.wilson@email.com', '2024-01-17 09:00:00+00',
 'North Point Inspection', 'REPORT_PENDING', 'Survey done, generating report',
 (SELECT id FROM users WHERE email = 'surveyor1@msinspections.com')),

('GHI789', 'Chevrolet', 'Malibu', 2018, '1G1ZD5ST4JF123456', 'White', 55000,
 'Alice Brown', '+1-555-0104', 'alice.brown@email.com', '2024-01-18 11:00:00+00',
 'South Bay Motors', 'COMPLETED', 'Full inspection completed',
 (SELECT id FROM users WHERE email = 'surveyor2@msinspections.com'));

-- Insert sample reports
INSERT INTO reports (survey_id, summary, findings, recommendations, estimated_cost, generated_by)
SELECT 
    s.id,
    'Vehicle inspection completed with minor issues identified.',
    'Minor scratches on rear bumper, tire wear within acceptable limits, all mechanical systems functioning properly.',
    'Recommend touch-up paint for scratches, monitor tire wear.',
    250.00,
    u.id
FROM surveys s
JOIN users u ON u.email = 'surveyor1@msinspections.com'
WHERE s.registration_number = 'DEF456';

INSERT INTO reports (survey_id, summary, findings, recommendations, estimated_cost, generated_by)
SELECT 
    s.id,
    'Comprehensive vehicle inspection completed successfully.',
    'Vehicle in excellent condition, no significant issues found, all safety systems operational.',
    'Continue regular maintenance schedule.',
    0.00,
    u.id
FROM surveys s
JOIN users u ON u.email = 'surveyor2@msinspections.com'
WHERE s.registration_number = 'GHI789';

-- Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE surveys ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Users can only see their own data (except admins)
CREATE POLICY "Users can view own data" ON users
    FOR SELECT USING (auth.uid()::text = id::text OR 
                     EXISTS (SELECT 1 FROM users WHERE id::text = auth.uid()::text AND role = 'ADMIN'));

-- Surveys policies
CREATE POLICY "Users can view surveys based on role" ON surveys
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id::text = auth.uid()::text 
            AND (role = 'ADMIN' OR (role = 'SURVEYOR' AND id = surveys.surveyor_id) OR role = 'VIEWER')
        )
    );

-- Reports policies  
CREATE POLICY "Users can view reports based on role" ON reports
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id::text = auth.uid()::text 
            AND (role = 'ADMIN' OR role = 'VIEWER' OR 
                 (role = 'SURVEYOR' AND EXISTS (
                     SELECT 1 FROM surveys WHERE id = reports.survey_id AND surveyor_id = users.id
                 )))
        )
    );

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- Note: Default passwords for all users is "Admin@123" or "Surveyor@123"
-- Hash: $2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/VcSAg/9PS

